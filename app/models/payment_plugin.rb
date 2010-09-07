# -*- coding: utf-8 -*-
class PaymentPlugin < ActiveRecord::Base
  
  ENABLE_LABEL = { "有効" => true, "無効" => false }

  validates_presence_of :name, :model_name, :detail

  def get_plugin_instance
    return nil unless self.enable
    ret = nil
    class_name = self.model_name.classify
    if Object.const_defined?(class_name)
      ret = Object.const_get(class_name).new
    end
    return ret
  end

  def self.enable_select
    ENABLE_LABEL.collect{|key, value| [key, value]}
  end

  def validate
    return if self.model_name.nil?
    class_name = self.model_name.classify
    unless Object.const_defined?(class_name)
      errors.add(:model_name, "はインスタンス化できるクラス名を入力してください")
    else
      ret = Object.const_get(class_name).new
      errors.add(:model_name, "はPaymentPluginBaseをMix-inしたクラスを指定してください") if ret.methods.grep(/next_step/).length < 1
    end
  end

end