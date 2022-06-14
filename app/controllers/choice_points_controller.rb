class ChoicePointsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index new show create]

  def index
    if params[:query].present?
      @choice_points = ChoicePoint.search_by_title_and_description(params[:query])
    else
      @choice_points = ChoicePoint.all
    end

    @last_chance = ChoicePoint.all.order(deadline: :asc).select{|choicepoint| choicepoint.deadline > Date.today}.take(5)
  end

  def show
    @choice_point = ChoicePoint.find(params[:id])
    @expired = @choice_point.expired
    @user_has_voted = @choice_point.vote_from?(current_user)
    @highest_score = @choice_point.highest_score
    @belongs_to_current_user = @choice_point.user == current_user
    if @belongs_to_current_user
      @user_string = 'You asked…'
    else
      @user_string = "#{@choice_point.user.name} asks…"
    end
    @title = @choice_point.title

    @options = Option.all
    @choice_point_options = @options.where(choice_point_id: @choice_point[:id])
    @descriptions = @choice_point_options.map(&:description)
  end

  def new
    @choice_point = ChoicePoint.new
    # @choice_point.options.build
  end

  def create
    @choice_point = ChoicePoint.new(choice_point_params)
    @choice_point.user = current_user
    if @choice_point.save
      redirect_to new_choice_point_option_path(@choice_point)
    else
      render "choice_points/new"
    end
  end

  def vote
    @option = Option.find(params[:choice_point][:option])
    @vote = Vote.new
    @vote.user = current_user
    @vote.option = @option
    if @vote.save
      @option.increase_score(@vote)
      @choice_point = ChoicePoint.find(params[:id])
      redirect_to choice_point_path(@choice_point)
    else
      # I don't think this will work. Is this branch even needed?
      render :show
    end
  end

  def update
    @choice_point = ChoicePoint.find(params[:id])
    @chosen_option = Option.find(params[:choice_point][:chosen_option][:id])
    @chosen_option.chosen = true
    @chosen_option.save
    if params[:choice_point][:successful] == "1"
      @choice_point.successful = true
    elsif params[:choice_point][:successful] == "0"
      @choice_point.successful = false
    end
    @choice_point.feedback = "Feedback Provided"
    @choice_point.save
    @chosen_users = @chosen_option.users
    if @choice_point.successful
      @chosen_users.each do |user|
        user.update(reputation: user.reputation + 5)
      end
    end
    redirect_to choice_point_path(@choice_point)
    # if @belongs_to_current_user && @expired
    #   # render feedback form asks user to select chosen option (sets option chosen to true)
    #   # successful or not (adds true or false to ChoicePoint.success)
    #   # and in turn adjusts voter rep accordingly
    # end
  end

  def past
    @choice_points = ChoicePoint.all
    @belongs_to_current_user = @choice_points.where(user: current_user)
    @expired = @belongs_to_current_user.filter do |point|
      point.expired
    end
  end
    # if @belongs_to_current_user && @expired
    #   redirect_to choice_points(@belongs_to_current_user)
    # else
    #   render "choice_points/new"
    # end

  def active
    @choice_points = ChoicePoint.all
    @belongs_to_current_user = @choice_points.where(user: current_user)
    @ongoing = @belongs_to_current_user.filter do |point|
      point.ongoing
    end
  end

  private

  def choice_point_params
    params.require(:choice_point).permit(:title, :description, :deadline)
  end
end
