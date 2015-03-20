class Spree::PromotionBuilder
  include ActiveModel::Model

  attr_reader :promotion
  attr_accessor :base_code, :number_of_codes, :user

  validates :number_of_codes,
    numericality: { only_integer: true, greater_than: 0 },
    allow_nil: true

  validate :promotion_validity

  class_attribute :default_random_code_length
  class_attribute :code_builder_class
  self.default_random_code_length = 6
  self.code_builder_class = Spree::PromotionCode::Builder

  # @param promotion_attrs [Hash] The desired attributes for the newly promotion
  # @param attributes [Hash] The desired attributes for this builder
  # @param user [Spree::User] The user who triggered this promotion build
  def initialize(attributes={}, promotion_attributes={})
    @promotion = Spree::Promotion.new(promotion_attributes)
    super(attributes)
  end

  def perform
    return false unless valid?

    if can_build_codes?
      @promotion = code_builder.promotion_with_codes
    end

    @promotion.save
  end

  def number_of_codes= value
    @number_of_codes = value.presence.try(:to_i)
  end

  private

  def promotion_validity
    if !@promotion.valid?
      @promotion.errors.each do |attribute, error|
        errors[attribute].push error
      end
    end
  end

  def can_build_codes?
    @base_code && @number_of_codes
  end

  def code_builder
    code_builder_class.new(promotion: @promotion, base_code: @base_code, num_codes: @number_of_codes)
  end

  def code_builder_class
    self.class.code_builder_class
  end
end
