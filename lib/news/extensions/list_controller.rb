# frozen_string_literal: true

module News
  module Extensions
    module ListController
      def self.prepended(base)
        base.skip_before_action :ensure_logged_in, only: [:news]
      end
    end
  end
end
