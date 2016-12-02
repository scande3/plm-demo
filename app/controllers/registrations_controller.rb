# Modified from https://github.com/plataformatec/devise/blob/master/app/controllers/devise/registrations_controller.rb

class RegistrationsController < Devise::RegistrationsController
  # POST /resource
  # There is likely a better way to hack this in... potentially be modifying build_resource that I'm not doing currently
  # as that appears to be used by several places and I lack the time to track it down.
  def create
    build_resource(sign_up_params)
    params[:user][:condition_term_lookup].each do |s|
      condition_obj = ConditionTerm.new
      condition_obj.concept_uri = Mei::Helper.strip_uri(s) if s.present?
      resource.condition_terms << condition_obj
    end

    geo_hash = Geomash.parse(params[:user][:geographic_term])
    resource.tgn_uri = "http://vocab.getty.edu/tgn/#{geo_hash[:tgn][:id]}" if geo_hash[:tgn].present?

    resource.save
    yield resource if block_given?
    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  # POST /resource
  # There is likely a better way to hack this in... potentially be modifying update_resource that I'm not doing currently
  # as that appears to be used by several places and I lack the time to track it down.
  def update
    do_geo_update = @user.geographic_term != params[:user][:geographic_term]
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)


    params[:user][:condition_term_lookup].map! {|c| Mei::Helper.strip_uri(c) }

    resource.condition_terms.each do |condition_term|
      unless params[:user][:condition_term_lookup].include?(condition_term.concept_uri)
        condition_term.delete
      end
    end

    condition_uri_array = resource.condition_terms.map {|c| c.concept_uri }
    params[:user][:condition_term_lookup].each do |s|
      unless condition_uri_array.include?(s)
        condition_obj = ConditionTerm.new
        condition_obj.concept_uri = s if s.present?
        resource.condition_terms << condition_obj
      end

    end

    # Only update if the geograpgic term has changed since this operation is expensive
    if do_geo_update
      resource.tgn_uri = nil
      geo_hash = Geomash.parse(params[:user][:geographic_term])
      resource.tgn_uri = "http://vocab.getty.edu/tgn/#{geo_hash[:tgn][:id]}" if geo_hash[:tgn].present?
    end

    resource_updated = update_resource(resource, account_update_params)
    yield resource if block_given?
    if resource_updated
      if is_flashing_format?
        flash_key = update_needs_confirmation?(resource, prev_unconfirmed_email) ?
            :update_needs_confirmation : :updated
        set_flash_message :notice, flash_key
      end
      bypass_sign_in resource, scope: resource_name
      respond_with resource, location: after_update_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :geographic_term)
  end

  def account_update_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :current_password, :geographic_term)
  end
end