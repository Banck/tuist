# frozen_string_literal: true

class OrganizationInviteService < ApplicationService
  attr_reader :inviter, :invitee, :organization_id

  module Error
    class Unauthorized < CloudError
      def message
        "You do not have a permission to invite users to this organization."
      end
    end

    class OrganizationNotFound < CloudError
      attr_reader :organization_id

      def initialize(organization_id)
        @organization_id = organization_id
      end

      def message
        "Organization with id #{organization_id} was not found"
      end
    end
  end

  def initialize(inviter:, invitee:, organization_id:)
    super()
    @inviter = inviter
    @invitee = invitee
    @organization_id = organization_id
  end

  def call
    begin
      organization = Organization.find(organization_id)
    rescue ActiveRecord::RecordNotFound
      raise Error::OrganizationNotFound.new(organization_id)
    end
    raise Error::Unauthorized unless OrganizationPolicy.new(inviter, organization).update?
    token = Devise.friendly_token.first(16)
    invitation = inviter.invitations.create!(
      invitee: invitee,
      organization_id: organization.id,
      token: token
    )
    InvitationMailer
      .invitation_mail(
        invitation: invitation
      )
      .deliver_now
    invitation
  end
end
