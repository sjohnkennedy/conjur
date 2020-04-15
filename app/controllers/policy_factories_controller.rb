# frozen_string_literal: true

# This controller is responsible for creating host records using
# host factory tokens for authorization.
class PolicyFactoriesController < ApplicationController
  include FindResource
  include AuthorizeResource

  RenderContext = Struct.new(:role, :params) do
    def get_binding
      binding
    end
  end

  def create_policy
    authorize :execute

    factory = ::PolicyFactory[resource_id]

    template = Conjur::PolicyParser::YAML::Loader.load(factory.template)

    context = RenderContext.new(current_user, params)

    template.each do |record|
      update_record(record, context)
    end

    policy_text = template.to_yaml

    response = load_policy(factory.base_policy, policy_text, policy_context) unless dry_run?

    response = {
      policy_text: policy_text,
      load_to: factory.base_policy.identifier,
      dry_run: dry_run?,
      response: response
    }
    render json: response, status: :created
  end

  def update_record(record, context)
    record.class.fields.each do |name, _type|
      record_value = record.send(name)
      
      if record_value.class < Conjur::PolicyParser::Types::Base
        update_record(record_value, context)
      elsif record_value.is_a?(Array)
        update_array(record_value, context)
      elsif record_value.is_a?(Hash)
        update_hash(record_value, context)
      elsif record_value.is_a?(String)
        rendered_value = ERB.new(record_value).result(context.get_binding)
        record.send("#{name}=", rendered_value)
      end
    end

    record
  end
  
  def update_array(arr, context)
    arr.map! do |item|
      if item.class < Conjur::PolicyParser::Types::Base
        update_record(item, context)
      elsif item.is_a?(Array)
        update_array(item, context)
      elsif item.is_a?(Hash)
        update_hash(item, context)
      elsif item.is_a?(String)
        ERB.new(item).result(context.get_binding)
      else
        item
      end
    end

    arr
  end

  def update_hash(hsh, context)
    hsh.each do |k, val|
      if val.class < Conjur::PolicyParser::Types::Base
        update_record(val, context)
      elsif val.is_a?(Array)
        update_array(val, context)
      elsif val.is_a?(Hash)
        update_hash(val, context)
      elsif val.is_a?(String)
        hsh[k] = ERB.new(val).result(context.get_binding)
      end
    end
  end

  def get_template
    authorize :read

    factory = ::PolicyFactory[resource_id]

    response = {
      body: factory.template
    }

    render json: response
  end

  def update_template
    authorize :update

    factory = ::PolicyFactory[resource_id]

    factory.template = request.body.read
    factory.save

    response = {
      body: factory.template
    }

    render json: response, status: :accepted
  end

  protected

  def policy_context
    multipart_data.reject { |k,v| k == :policy }
  end

  def multipart_data
    return {} if request.raw_post.empty?

    @multipart_data ||= Util::Multipart.parse_multipart_data(
      request.raw_post,
      content_type: request.headers['CONTENT_TYPE']
    )
  end

  def dry_run?
    params[:dry_run].present?
  end

  def resource_kind
    'policy_factory'
  end

  def load_policy(load_to, policy_text, policy_context)

    policy_version = PolicyVersion.new(
      role: current_user, 
      policy: load_to, 
      policy_text: policy_text
    )
    policy_version.perform_automatic_deletion = false
    policy_version.delete_permitted = false
    policy_version.update_permitted = true
    policy_version.save
    loader = Loader::Orchestrate.new(policy_version, context: policy_context)
    loader.load

    created_roles = loader.new_roles.select do |role|
      %w(user host).member?(role.kind)
    end.inject({}) do |memo, role|
      credentials = Credentials[role: role] || Credentials.create(role: role)
      memo[role.id] = { id: role.id, api_key: credentials.api_key }
      memo
    end

    {
      created_roles: created_roles,
      version: policy_version.version
    }
  end
end
