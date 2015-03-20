class Spree::PromotionCode::Builder
  attr_reader :promotion, :num_codes, :base_code

  class_attribute :promotion_code_class
  self.promotion_code_class = Spree::PromotionCode

  def initialize(base_code:, num_codes:, promotion:)
    @base_code = base_code
    @num_codes = num_codes
    @promotion = promotion
  end

  def build_promotion_codes
    codes.map do |code|
      promotion.codes.build(value: code)
    end
  end

  def promotion_with_codes
    build_promotion_codes
    promotion
  end

  private

  def codes
    if num_codes > 1
      generate_random_codes
    else
      [base_code]
    end
  end

  def generate_random_codes
    loop do
      code_list = number_of_codes.times.map { generate_random_code }

      return code_list if code_list_unique?(code_list)
    end
  end

  def generate_random_code
    suffix = Array.new(self.class.default_random_code_length) { sample_random_character }.join
    "#{@base_code}_#{suffix}"
  end

  def sample_random_character
    @_sample_characters ||= ('a'..'z').to_a
    @_sample_characters.sample
  end

  def code_list_unique? code_list
    code_list.length == code_list.uniq.length &&
      promotion_code_class.where(value: code_list).empty?
  end

  def promotion_code_class
    self.class.promotion_code_class
  end
end
