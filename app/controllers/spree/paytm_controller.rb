module Spree
  class PayumoneyController < StoreController
    protect_from_forgery only: :index
    
    def index
      @param_list
    end

    def confirm
    end
  end
end