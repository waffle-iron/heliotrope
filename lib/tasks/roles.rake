desc 'Add application-wide admin privileges to a user'
task admin: :environment do
  puts 'Creating an admin user.'
  u = prompt_to_create_user
  Role.create(user: u, resource: nil, role: 'admin')
  puts 'User created.'
end

desc 'Create a new press'
task press: :environment do
  print 'Press name: '
  name = $stdin.gets.chomp

  press = Press.create!(name: name)

  puts 'Who can admin this press?'

  u = prompt_to_create_user

  Role.create(user: u, resource: press, role: 'admin')
  puts 'press created.'
end

def prompt_to_create_user
  User.find_or_create_by!(email: prompt_for_email) do |u|
    puts 'User not found. Enter a password to create the user.'
    u.password = prompt_for_password
  end
rescue => e
  puts e
  retry
end

def prompt_for_email
  print 'Email: '
  $stdin.gets.chomp
end

def prompt_for_password
  begin
    system 'stty -echo'
    print 'Password (must be 8+ characters): '
    password = $stdin.gets.chomp
    puts "\n"
  ensure
    system 'stty echo'
  end
  password
end
