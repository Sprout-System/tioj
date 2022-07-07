class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :store_location
  before_action :set_verdict_hash
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_anno

  def set_verdict_hash
    @verdict = {
      "AC" => "Accepted",
      "WA" => "Wrong Answer",
      "TLE" => "Time Limit Exceeded",
      "MLE" => "Memory Limit Exceeded",
      "OLE" => "Output Limit Exceeded",
      "RE" => "Runtime Error",
      "SIG" => "Runtime Error (killed by signal)",
      "EE" => "Execution Error",
      "CE" => "Compilation Error",
      "CLE" => "Compilation Limit Exceeded",
      "ER" => "Judge Compilation Error",
      "JE" => "Judge Error",
    }
    @v2i = {
      "AC" => 0,
      "WA" => 1,
      "TLE" => 2,
      "MLE" => 3,
      "OLE" => 4,
      "RE" => 5,
      "SIG" => 6,
      "EE" => 7,
      "CE" => 8,
      "CLE" => 9,
      "ER" => 10,
      "JE" => 11,
    }
    @i2v = @v2i.map{|x, y| [y, x]}.to_h
  end

  def store_location
    if (request.fullpath != "/users/sign_in" &&
        request.fullpath != "/users/sign_out"&&
        request.fullpath != "/users/password"&&
        request.fullpath != "/users/sign_up" &&
        !request.xhr?)
      session[:previous_url] = request.fullpath
    end
  end
  def after_sign_in_path_for(resource)
    session[:previous_url] || root_path
  end

protected
  def authenticate_admin!
    authenticate_user!
    if not current_user.admin?
      flash[:alert] = 'Insufficient User Permissions.'
      redirect_to action:'index'
      return
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) do |u|
      u.permit(:school, :gradyear, :name, :email, :nickname, :username, :password, :password_confirmation, :remember_me)
    end
    devise_parameter_sanitizer.permit(:sign_in) do |u|
      u.permit(:login, :username, :email, :password, :remember_me)
    end
    devise_parameter_sanitizer.permit(:account_update) do |u|
      u.permit(:school, :gradyear, :name, :avatar, :avatar_cache, :motto, :email, :nickname, :password, :password_confirmation, :current_password)
    end
  end

  def set_contest_layout
    if @contest.blank?
      "application"
    else
      "contest"
    end
  end

  def set_anno
    @annos = Announcement.order(:id).all.to_a
  end

  def get_sorted_user(limit = nil)
    attributes = [
      "users.*",
      "COUNT(DISTINCT CASE WHEN s.result = 'AC' THEN s.problem_id END) ac",
      "COUNT(DISTINCT CASE WHEN s.result = 'AC' THEN s.id END) acsub",
      "COUNT(s.id) sub",
      "COUNT(DISTINCT CASE WHEN s.result = 'AC' THEN s.id END) / COUNT(s.id) acratio",
    ]
    query = User.select(*attributes)
        .joins("LEFT JOIN submissions s ON s.user_id = users.id AND s.contest_id IS NULL")
        .group(:id).order('ac DESC', 'acratio DESC', 'sub DESC', :id)
    if limit
      query = query.limit(limit)
    end
    query.to_a
  end

  def td_list_to_arr(str, sz)
    str.split(',').map{|x|
      t = x.split('-')
      Range.new([0, t[0].to_i].max, [t[-1].to_i, sz - 1].min).to_a
    }.flatten.sort.uniq
  end

  def reduce_td_list(str, sz)
    td_list_to_arr(str, sz).chunk_while{|x, y|
      x + 1 == y
    }.map{|x|
      x.size == 1 ? x[0].to_s : x[0].to_s + '-' + x[-1].to_s
    }.join(',')
  end

  def inverse_td_list(prob)
    sz = prob.testdata.count
    prob.testdata_sets.map.with_index{|x, i| td_list_to_arr(x.td_list, sz).map{|y| [y, i]}}
        .flatten(1).group_by(&:first).map{|x, y| [x, y.map(&:last)]}.to_h
  end
end
