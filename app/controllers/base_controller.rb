# -*- coding: utf-8 -*-
class BaseController < ApplicationController
  before_filter :start_transaction
  before_filter :verify_session_token
  before_filter :load_data
  before_filter :set_headers
  after_filter :end_transaction
  layout 'base'
  mobile_filter
  trans_sid

  #バリデーションエラーの時、レイアウトが崩れる対応
  ActionView::Base.field_error_proc = Proc.new{ |snippet,
  instance| "<span class=\"error\">#{snippet}</span>"
  }
  
  def cart_total_prices carts
    carts.map(&:subtotal).sum
  end
  
  #エラーページ指定
  def rescue_action_in_public(exception)
    case exception
      when ActiveRecord::RecordNotFound, ::ActionController::UnknownAction, ::ActionController::RoutingError, ActionView::TemplateError, NoMethodError
      if request.mobile?
        render(:file => "public/404_mobile.html", :status => "404 NOT FOUND")
      else
        render(:file => "public/404.html", :status => "404 NOT FOUND")
      end
    else
      if request.mobile?
        render(:file => "public/500_mobile.html", :status => "500 ERROR")
      else
        render(:file => "public/500.html", :status => "500 ERROR")
      end
    end
  end

  private

  def load_data
    load_system
    load_user
    load_cart
    load_category
  end

=begin rdoc
  1. ユーザ情報(ログインしている場合)
  2. session
  3. new carts
  の順でカートを取得します。
=end
  def load_cart
    #@carts = @login_customer.carts if @login_customer
    #@carts ||= session[:carts]
    if @carts.nil? && session[:carts]
      @carts = session[:carts].map do | hash |
        if @login_customer
          @login_customer.carts.build(hash)
        else
          Cart.new(hash)
        end
      end
    end
    @carts ||= []

    @cart_price = cart_total_prices(@carts)
  end

  def save_carts(carts=nil)
    carts ||= @carts
    carts or return
    session[:carts] = carts.map(&:attributes)
  end

  def load_category
  end

  def load_user
    if session[:customer_id]
      @login_customer = Customer.find_by_id(session[:customer_id])
    elsif cookies[:auto_login]
      @login_customer = Customer.find_by_cookie(cookies[:auto_login])
      cookies.delete(:auto_login) unless @login_customer
    elsif request.mobile? && (request.mobile.ident_subscriber || request.mobile.ident_device)
      mo = request.mobile
      conds = []
      conds << ['activate = ?', Customer::TOUROKU]
      conds << ['mobile_serial = ?', mo.ident_subscriber] if mo.ident_subscriber
      customer = Customer.find(:first, :conditions => flatten_conditions(conds))
    end
  end

  def login_check
    unless session[:customer_id]
      session[:return_to] = params if params
      redirect_to(:controller => 'accounts', :action => 'login')
    end
  end

  def set_login_customer(customer)
    if customer.nil?
      return set_login_customer_id(nil)
    end
    customer.instance_of?(Customer) or return
    set_login_customer_id(customer.id)
  end

  def set_login_customer_id(id)
    cookies.delete(:auto_login) if id.nil?

    saved = {}
    keys = [:return_to, :carts]
    keys.each{|k| saved[k] = session[k]}

    reset_session
    session[:customer_id] = id
    keys.each{|k| session[k] = saved[k]}
  end

  def set_headers
    if request.mobile? and request.mobile.is_a?(Jpmobile::Mobile::Docomo)
      headers["Content-Type"] = "application/xhtml+xml"
    end
  end

  alias_method :non_application_rescue_action, :rescue_action
  def rescue_action(exception)
    ActiveRecord::Base.connection.rollback_db_transaction
    case exception
    when ActiveRecord::RecordNotFound
      if request.mobile?
        render :text => IO.read(File.join(RAILS_ROOT, 'public', '404_mobile.html')), :status => 404, :layout => false
      else
        render :text => IO.read(File.join(RAILS_ROOT, 'public', '404.html')), :status => 404, :layout => false
      end
    else
     non_application_rescue_action(exception)
    end
  end

  def start_transaction
    ActiveRecord::Base.connection.begin_db_transaction
  end

  def end_transaction
    ActiveRecord::Base.connection.commit_db_transaction
  end

  alias_method :old_render_optional_error_file, :render_optional_error_file

  def render_optional_error_file(status_code)
    if is_lisagas?
      old_render_optional_error_file(status_code)
    else
      status = interpret_status(status_code)
      path = "#{Rails.public_path}/#{status[0,3]}_mobile.html"
      if File.exist?(path)
        render :file => path, :status => status
      else
        old_render_optional_error_file(status_code)
      end
    end
  end

  def reset_session
    session[:customer_id] = nil
  end
end
