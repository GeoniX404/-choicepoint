# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

USERNAMES = ['rmgodfrey', 'aackle00', 'GeoniX404', 'chriswall24']
CHOICE_POINTS = {
  "What should I wear to my job interview?" => ["Button-up shirt", "Suit", "T-shirt"],
  "What car should I buy?" => ["Chevrolet", "Toyota"],
  "Where should I live?" => ["Tokyo", "New York", "London", "Paris", "Sydney", "Berlin"]
}.to_a
DEADLINE_FIRST = Time.now
DEADLINE_LAST = Time.new(2023)
NUMBER_OF_CHOICE_POINTS = 3

def create_users
  USERNAMES.each do |username|
    user = User.create!(
      email: Faker::Internet.email,
      password: Faker::Internet.password,
      name: username
    )
    create_choice_points(user)
  end
end

def create_choice_points(user)
  NUMBER_OF_CHOICE_POINTS.times do
    title, option_descriptions = CHOICE_POINTS.sample
    choice_point = ChoicePoint.create!(
      title: title,
      description: Faker::Lorem.sentence,
      user: user,
      # Gets a random time between DEADLINE_FIRST and DEADLINE_LAST
      # See "https://stackoverflow.com/questions/2683857/how-to-generate-a-random-date-and-time-between-two-dates"
      deadline: Time.at(
        ((DEADLINE_LAST.to_f - DEADLINE_FIRST.to_f) * rand) + DEADLINE_FIRST.to_f
      )
    )
    create_options(choice_point, option_descriptions)
  end
end

def create_options(choice_point, option_descriptions)
  option_descriptions.each do |description|
    Option.create!(
      description: description,
      pros: Faker::Lorem.sentence,
      cons: Faker::Lorem.sentence,
      choice_point: choice_point
    )
  end
end

puts "Destroying existing users and choice points"
User.destroy_all
puts "Creating seeds..."
create_users
puts "New seeds created"
