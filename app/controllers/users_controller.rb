class UsersController < ApplicationController
  def index
    @users = User.all.sort{|a, b| (a.ac_count == b.ac_count ? b.ac_ratio <=> a.ac_ratio : b.ac_count <=> a.ac_count) }
    @users = Kaminari.paginate_array(@users).page(params[:page]).per(25)
  end
  def show
    @user = User.friendly.find(params[:id])
    @problems = Problem.all.order("id ASC")
    rescue ActiveRecord::RecordNotFound => e
      redirect_to :back, :alert => "Username '#{params[:id]}' not found."
      return
    end
  end
end
