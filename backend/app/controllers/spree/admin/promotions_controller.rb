module Spree
  module Admin
    class PromotionsController < ResourceController
      before_filter :load_data
      before_filter :load_bulk_code_information, only: [:edit]

      create.before :build_promotion_codes

      helper 'spree/promotion_rules'

      def create
        @promotion = Spree::Promotion.new permitted_resource_params

        if permitted_promo_builder_params.any?
          code_builder = Spree::PromotionCode::Builder.new(permitted_promo_builder_params.merge(promotion: @promotion))
          code_builder.build_codes
          @promotion = code_builder.promotion
        end

        if @promotion.save
          flash[:success] = Spree.t(:successfully_created, resource: @promotion.class.model_name.human)
          redirect_to location_after_save
        else
          flash[:error] = @promotion_builder.errors.full_messages.join(", ")
          render action: 'new'
        end
      end

      protected
        def load_bulk_code_information
          @promotion_builder = Spree::PromotionBuilder.new(
            base_code: @promotion.codes.first.try!(:value),
            number_of_codes: @promotion.codes.count,
          )
        end

        def location_after_save
          spree.edit_admin_promotion_url(@promotion)
        end

        def load_data
          @calculators = Rails.application.config.spree.calculators.promotion_actions_create_adjustments
          @promotion_categories = Spree::PromotionCategory.order(:name)
        end

        def collection
          return @collection if @collection.present?
          params[:q] ||= HashWithIndifferentAccess.new
          params[:q][:s] ||= 'id desc'

          @collection = super
          @search = @collection.ransack(params[:q])
          @collection = @search.result(distinct: true).
            includes(promotion_includes).
            page(params[:page]).
            per(params[:per_page] || Spree::Config[:promotions_per_page])

          @collection
        end

        def promotion_includes
          [:promotion_actions]
        end

        def permitted_promo_builder_params
          if params[:promotion_builder]
            params[:promotion_builder].permit(:base_code, :number_of_codes)
          else
            {}
          end
        end
    end
  end
end
