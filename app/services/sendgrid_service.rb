require "sendgrid-ruby"

class SendgridService
  include SendGrid

  def initialize
    @sg = SendGrid::API.new(api_key: Rails.application.credentials.dig(:sendgrid, :api_key))
  end

  def create_domain(domain)
    begin
      Rails.logger.info "Creating domain in SendGrid: #{domain}"

      data = {
        "domain" => domain,
        "subdomain" => "mail"
      }

      Rails.logger.info "SendGrid API request data: #{data.inspect}"
      response = @sg.client.whitelabel.domains.post(request_body: data)

      Rails.logger.info "SendGrid API response status: #{response.status_code}"
      Rails.logger.info "SendGrid API response body: #{response.body}"

      if response.status_code.to_i == 201
        parsed_response = JSON.parse(response.body)
        dns_records = extract_dns_records(parsed_response)

        {
          success: true,
          domain_id: parsed_response["id"],
          dns_records: dns_records,
          message: "Domain created successfully"
        }
      else
        Rails.logger.error "SendGrid domain creation failed with status #{response.status_code}: #{response.body}"
        {
          success: false,
          error: "Failed to create domain: #{response.body}",
          status_code: response.status_code
        }
      end
    rescue => e
      Rails.logger.error "SendGrid API exception: #{e.class.name} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      {
        success: false,
        error: "SendGrid API error: #{e.message}"
      }
    end
  end

  def verify_domain(domain_id)
    begin
      response = @sg.client.whitelabel.domains._(domain_id).validate.post

      if response.status_code.to_i == 200
        parsed_response = JSON.parse(response.body)

        {
          success: true,
          verified: parsed_response["valid"],
          validation_results: parsed_response["validation_results"],
          message: parsed_response["valid"] ? "Domain verified successfully" : "Domain verification failed"
        }
      else
        {
          success: false,
          error: "Failed to verify domain: #{response.body}",
          status_code: response.status_code
        }
      end
    rescue => e
      {
        success: false,
        error: "SendGrid API error: #{e.message}"
      }
    end
  end

  def get_domain_status(domain_id)
    begin
      response = @sg.client.whitelabel.domains._(domain_id).get

      if response.status_code.to_i == 200
        parsed_response = JSON.parse(response.body)

        {
          success: true,
          verified: parsed_response["valid"],
          domain_data: parsed_response
        }
      else
        {
          success: false,
          error: "Failed to get domain status: #{response.body}",
          status_code: response.status_code
        }
      end
    rescue => e
      {
        success: false,
        error: "SendGrid API error: #{e.message}"
      }
    end
  end

  def list_domains
    begin
      response = @sg.client.whitelabel.domains.get

      if response.status_code.to_i == 200
        parsed_response = JSON.parse(response.body)

        {
          success: true,
          domains: parsed_response
        }
      else
        {
          success: false,
          error: "Failed to list domains: #{response.body}",
          status_code: response.status_code
        }
      end
    rescue => e
      {
        success: false,
        error: "SendGrid API error: #{e.message}"
      }
    end
  end

  def delete_domain(domain_id)
    begin
      response = @sg.client.whitelabel.domains._(domain_id).delete

      if response.status_code.to_i == 204
        {
          success: true,
          message: "Domain deleted successfully"
        }
      else
        {
          success: false,
          error: "Failed to delete domain: #{response.body}",
          status_code: response.status_code
        }
      end
    rescue => e
      {
        success: false,
        error: "SendGrid API error: #{e.message}"
      }
    end
  end

  private

  def extract_dns_records(domain_data)
    dns_records = []

    # Extract DNS records from SendGrid response
    if domain_data["dns"] && domain_data["dns"]["mail_cname"]
      dns_records << {
        type: "CNAME",
        host: domain_data["dns"]["mail_cname"]["host"],
        value: domain_data["dns"]["mail_cname"]["data"]
      }
    end

    if domain_data["dns"] && domain_data["dns"]["dkim1"]
      dns_records << {
        type: "CNAME",
        host: domain_data["dns"]["dkim1"]["host"],
        value: domain_data["dns"]["dkim1"]["data"]
      }
    end

    if domain_data["dns"] && domain_data["dns"]["dkim2"]
      dns_records << {
        type: "CNAME",
        host: domain_data["dns"]["dkim2"]["host"],
        value: domain_data["dns"]["dkim2"]["data"]
      }
    end

    dns_records
  end
end
