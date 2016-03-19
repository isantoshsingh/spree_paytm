module Spree
  class Gateway::Paytm < Gateway
    preference :merchant_id, :string
    preference :merchant_key, :string
    preference :website, :string
    preference :industry_type_id, :string
    preference :channel_id, :string

    def provider_class
      self
    end

    def provider
      self
    end

    def auto_capture?
      true
    end

    def method_type
      "paytm"
    end

    def support?(source)
      true
    end

    def authorization
      self
    end

    def purchase(amount, source, gateway_options={})
      ActiveMerchant::Billing::Response.new(true, "paytm success")
    end

    def success?
      true
    end

    def txnid(order)
      order.id.to_s + order.number.to_s
    end

    def source_required?
      false
    end
    
    def refund_url
      'https://' + domain + '/oltp/HANDLER_INTERNAL/REFUND'
    end

    def status_query_url
      'https://' + domain + '/oltp/HANDLER_INTERNAL/TXNSTATUS'
    end

    def txn_url
      'https://' + domain + '/oltp-web/processTransaction'
    end

    private
    def domain
      domain = 'pguat.paytm.com'
      if (preferred_test_mode == true)
        domain = 'secure.paytm.com'
      end
      domain
    end
    
  end
end