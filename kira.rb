require 'telegram/bot'
require "active_record"
require 'date'

db_config_admin = {
  'database' => 'kira', 
  'schema_search_path' => 'public',
  'adapter' => 'postgresql',
  'encoding' => 'utf-8',
  'pool' => 5
  }
ActiveRecord::Base.establish_connection(db_config_admin)

token = '142057399:AAG9VFZLHeymfJYrIyVLUKu0PfYsnmA2C8Q'

class Expenses < ActiveRecord::Base
end

def get_expenses(month, year, chat_id)
  Expenses.where("extract(month from created_at) = #{month} and extract(year from created_at) = #{year} and chat_id = '#{chat_id}'")
end

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    begin
      expenses = get_expenses(Time.now.month , Time.now.year, message.chat.id)
      puts message.inspect
      msg = message.text.split(" ") rescue []
      case msg[0]
      when '/help', '/start'
        help_msg = "List of commands: \n"
        help_msg << "/l : Listing your expenses \n"
        help_msg << "/a <item> <price> : Adding expenses record. Item name can be spaced. \n"
        help_msg << "/d <id> : Removing expenses \n"
        help_msg << "/g <month> <year> : Getting expenses for a month of a year.\n"
        help_msg << "Thank you. Please contact yakob.ubaidi@gmail.com for any issue."
        bot.api.send_message(chat_id: message.chat.id, text: help_msg)
      when '/l', '/list'
        puts '/list'
        tmp = "Expenses for #{Date::MONTHNAMES[Time.now.month]} #{Time.now.year} \n"
        expenses.each_with_index do |e, idx|
          tmp << "#{idx+1}. #{e.name.strip} (id:" + e.id.to_s + ") : #{e.price} \n"
        end
        tmp << "Total : RM#{expenses.sum(:price)}"
        bot.api.send_message(chat_id: message.chat.id, text: tmp)
      when '/d' , '/del'
        if msg[1]
          Expenses.find(msg[1]).destroy
          bot.api.send_message(chat_id: message.chat.id, text: "Expenses deleted")
        end
      when '/g' , '/get_month'
        if msg[1] && msg[2]
          expenses = get_expenses(msg[1], msg[2], message.chat.id)
          tmp = "Expenses for #{msg[1]} #{msg[2]} : \n"
          expenses.each_with_index do |e, idx|
            tmp << "#{idx+1}. #{e.name} (id:" + e.id.to_s + ") : #{e.price} \n"
          end
          tmp << "Total : RM#{expenses.sum(:price)}"
          bot.api.send_message(chat_id: message.chat.id, text: tmp)
        else
          bot.api.send_message(chat_id: message.chat.id, text: "use /get_month <month> <year>")
        end
      when '/a', '/add'
        splitted =  message.text.split(" ")
        namex = splitted[1..-2].join(" ")
        price = splitted[-1]
        if namex && price && namex != price
          tmp = Expenses.create(name: namex, price: price, created_at: Time.now, chat_id: "#{message.chat.id}")
          sum = expenses.sum(:price)
          bot.api.send_message(chat_id: message.chat.id, text: "Expenses #{namex} (id:#{tmp.id}) added. Total expenses for this month is RM#{sum} ")
        end
        # Expenses.create(name: name, price: price, created_at: Time.now, chat_id: message.chat.id)
      end
      
    rescue Exception => e
      bot.api.send_message(chat_id: message.chat.id, text: e)
    end
  end
end
