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

    def request_type
      'DEFAULT' #or SUBSCRIBE
    end
    ### function returns dictionary of encrypted data ###
    ### accepts a dictionary with data and key to encrypt with ###
    ### can accept multiple key value pairs in the dictionary ###
    def new_pg_encrypt(params)
      if (params.class != Hash) || (params.keys == [])
        return false
      end

      encrypted_data = Hash[]
      key = preferred_merchant_key
      keys = params.keys
      aes = OpenSSL::Cipher::Cipher.new("aes-128-cbc")
      begin
        keys.each do |k|
          data = params[k]
          aes.encrypt
          aes.key = key
          aes.iv = '@@@@&&&&####$$$$'
          encrypted_k = aes.update(k.to_s) + aes.final
          encrypted_k = Base64.encode64(encrypted_k.to_s)
          aes.encrypt
          aes.key = key
          aes.iv = '@@@@&&&&####$$$$'
          encrypted_data[encrypted_k] = aes.update(data.to_s) + aes.final
          encrypted_data[encrypted_k] = Base64.encode64(encrypted_data[encrypted_k])
        end
      rescue Exception => e
        return false
      end
      return encrypted_data
    end

    ### function returns a single encrypted value ###
    ### input data -> value to be encrypted ###
    def new_pg_encrypt_variable(data)
      aes = OpenSSL::Cipher::Cipher.new("aes-128-cbc")
      aes.encrypt
      aes.key = preferred_merchant_key
      aes.iv = '@@@@&&&&####$$$$'
      encrypted_data = nil
      begin
        encrypted_data = aes.update(data.to_s) + aes.final
        encrypted_data = Base64.encode64(encrypted_data)
      rescue Exception => e
        return false
      end
      return encrypted_data
    end


    ### function returns dictionary of decrypted data ###
    ### accepts a dictionary with data and key to decrypt with ###
    ### can accept multiple key value pairs in the dictionary ###
    def new_pg_decrypt(params)
      if (params.class != Hash) || (params.keys == [])
        return false
      end

      decrypted_data = Hash[]
      key = preferred_merchant_key
      keys = params.keys
      aes = OpenSSL::Cipher::Cipher.new("aes-128-cbc")
      begin
        keys.each do |k|
          data = params[k]
          aes.decrypt
          aes.key = key
          aes.iv = '@@@@&&&&####$$$$'
          decrypted_k = Base64.decode64(k.to_s)
          decrypted_k = aes.update(decrypted_k.to_s) + aes.final
          if data.empty?
            decrypted_data[decrypted_k] = ""
            next
          end
          aes.decrypt
          aes.key = key
          aes.iv = '@@@@&&&&####$$$$'
          data = Base64.decode64(data)
          decrypted_data[decrypted_k] = aes.update(data) + aes.final
        end
      rescue Exception => e
        return false
      end
      return decrypted_data
    end


    ### function returns a single decrypted value ###
    ### input data -> value to be decrypted ###
    def new_pg_decrypt_variable(data)
      aes = OpenSSL::Cipher::Cipher.new("aes-128-cbc")
      aes.decrypt
      aes.key = preferred_merchant_key
      aes.iv = '@@@@&&&&####$$$$'
      decrypted_data = nil
      begin
        decrypted_data = Base64.decode64(data.to_s)
        decrypted_data = aes.update(decrypted_data) + aes.final
      rescue Exception => e
        return false
      end
      return decrypted_data
    end


    def new_pg_generate_salt(length)
      salt = SecureRandom.urlsafe_base64(length*(3.0/4.0))
      return salt.to_s
    end


    ### function returns checksum of given key value pairs ###
    ### accepts a hash with key value pairs ###
    ### calculates sha256 checksum of given values ###
    def new_pg_checksum(params, salt_length = 4)
      if params.class != Hash
        return false
      end
      key = preferred_merchant_key
      salt = new_pg_generate_salt(salt_length)
      keys = params.keys
      str = nil
      keys = keys.sort
      keys.each do |k|
        if str.nil?
          str = params[k].to_s
          next
        end
        str = str + '|'  + params[k].to_s
      end
      str = str + '|' + salt
      check_sum = Digest::SHA256.hexdigest(str)
      check_sum = check_sum + salt
      ### encrypting checksum ###
      check_sum = new_pg_encrypt_variable(check_sum)
      return check_sum
    end


    ### function returns checksum of given key value pairs (must contain the :checksum key) ###
    ### accepts a hash with key value pairs ###
    ### calculates sha256 checksum of given values ###
    ### returns true if checksum is consistent ###
    ### returns false in case of inconsistency ###
    def new_pg_verify_checksum(params, check_sum, salt_length = 4)

      if params.class != Hash
        return false
      end

      if check_sum.nil? || check_sum.empty?
        return false
      end
      key = preferred_merchant_key
      generated_check_sum = nil
      check_sum = new_pg_decrypt_variable(check_sum)

      if check_sum == false
        return false
      end
      begin
        salt = check_sum[(check_sum.length-salt_length), (check_sum.length)]
        keys = params.keys
        str = nil
        keys = keys.sort
        keys.each do |k|
          if str.nil?
            str = params[k].to_s
            next
          end
          str = str + '|' + params[k].to_s
        end
        str = str + '|' + salt
        generated_check_sum = Digest::SHA256.hexdigest(str)
        generated_check_sum = generated_check_sum + salt
      rescue Exception => e
        return false
      end

      if check_sum == generated_check_sum
        return true
      else
        return false
      end
    end

    private
    def domain
      domain = 'secure.paytm.com'
      if (preferred_test_mode == true)
        domain = 'pguat.paytm.com'
      end
      domain
    end
  end
end