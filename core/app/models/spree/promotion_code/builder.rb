class Spree::PromotionCode::Builder
  include ActiveModel::Model

  attr_reader :base_code, :number_of_codes, :promotion

  validates :base_code, :number_of_codes, :promotion, presence: true
  validates :number_of_codes, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  def initialize options
    @base_code = options[:base_code]
    @promotion = options[:promotion]
    @number_of_codes = options[:number_of_codes].presence.try(:to_i) || 1
  end

  def build_codes
    if valid?
      codes.each do |code|
        promotion.codes.build(value: code)
      end
      promotion.codes
    end
  end

  private

  def codes
    if number_of_codes == 1
      [base_code]
    else
      random_codes
    end
  end

  def random_codes
    loop do
      code_list = number_of_codes.times.map { code_with_randomness }
      if code_list.length == code_list.uniq.length && Spree::PromotionCode.where(value: code_list).empty?
        return code_list
      end
    end
  end

  def code_with_randomness
    "#{@base_code}_#{Array.new(Spree::PromotionBuilder.default_random_code_length){ ('a'..'z').to_a.sample }.join}"
  end
end
