# Copyright 2002-2013 Rally Software Development Corp. All Rights Reserved.
#
# This script is open source and is provided on an as-is basis. Rally provides
# no official support for nor guarantee of the functionality, usability, or
# effectiveness of this code, nor its suitability for any application that
# an end-user might have in mind. Use at your own risk: user assumes any and
# all risk associated with use and implementation of this script in his or
# her own environment.

require 'rally_api'
require 'csv'

$my_base_url       = "https://rally1.rallydev.com/slm"

$my_username       = "user@company.com"
$my_password       = "password"
$my_workspace      = "My Workspace"
$my_project        = "My Project"
$wsapi_version     = "1.40"

$filename          = 'parent_portfolio_items.csv'

# Load (and maybe override with) my personal/private variables from a file...
my_vars= File.dirname(__FILE__) + "/my_vars.rb"
if FileTest.exist?( my_vars ) then require my_vars end

def assign_parent_portfolio_item(header, row)

  child_pi_formatted_id        = row[header[0]].strip
  child_pi_type                = row[header[1]].gsub(/\s+/, "").downcase
  child_pi_name                = row[header[2]].strip
  parent_pi_formatted_id       = row[header[3]].strip
  parent_pi_type               = row[header[4]].gsub(/\s+/, "").downcase
  parent_pi_name               = row[header[5]].strip

  fetch_string = "ObjectID,FormattedID,Name,PortfolioItemType,Name"
  order_string = "FormattedID Asc"

  child_formatted_id_query_string = "(FormattedID = \"" + child_pi_formatted_id + "\")"
  child_name_query_string = "(Name = \"" + child_pi_name + "\")"

  parent_formatted_id_query_string = "(FormattedID = \"" + parent_pi_formatted_id + "\")"
  parent_name_query_string = "(Name = \"" + parent_pi_name + "\")"

  # First Construct and Try queries based on Formatted ID
  child_query_by_formatted_id = RallyAPI::RallyQuery.new()
  child_type_string = "portfolioitem/" + child_pi_type
  child_query_by_formatted_id.type = child_type_string
  child_query_by_formatted_id.fetch = fetch_string
  child_query_by_formatted_id.query_string = child_formatted_id_query_string
  child_query_by_formatted_id.order = order_string

  child_results_by_formatted_id = @rally.find(child_query_by_formatted_id)

  parent_query_by_formatted_id = RallyAPI::RallyQuery.new()
  parent_type_string = "portfolioitem/" + parent_pi_type
  parent_query_by_formatted_id.type = parent_type_string
  parent_query_by_formatted_id.fetch = fetch_string
  parent_query_by_formatted_id.query_string = parent_formatted_id_query_string
  parent_query_by_formatted_id.order = order_string

  parent_results_by_formatted_id = @rally.find(parent_query_by_formatted_id)

  # Annoying bug in K-P's workspace causes even correct FormattedID queries with confirmed
  # FormattedID present, to fail... so, try name-based lookup instead if this fails
  if child_results_by_formatted_id.total_result_count == 0 || parent_results_by_formatted_id.total_result_count == 0
    if child_results_by_formatted_id.total_result_count == 0
      puts "Child PI Item #{child_pi_formatted_id}: #{child_pi_name} not found via FormattedID Query...trying query by Name"

      child_query_by_name = RallyAPI::RallyQuery.new()
      child_query_by_name.type = child_type_string
      child_query_by_name.fetch = fetch_string
      child_query_by_name.query_string = child_name_query_string
      child_query_by_name.order = order_string

      child_results_by_name = @rally.find(child_query_by_name)
    else
      my_child_results = child_results_by_formatted_id
    end
    if parent_results_by_formatted_id.total_result_count == 0
      puts "Parent PI Item #{parent_pi_formatted_id}: #{parent_pi_name} not found via FormattedID Query...trying query by Name"

      parent_query_by_name = RallyAPI::RallyQuery.new()
      parent_query_by_name.type = parent_type_string
      parent_query_by_name.fetch = fetch_string
      parent_query_by_name.query_string = parent_name_query_string
      parent_query_by_name.order = order_string

      parent_results_by_name = @rally.find(parent_query_by_name)
    else
      my_parent_results = parent_results_by_formatted_id
      parent_results_by_name = parent_results_by_formatted_id
    end
  end

  # Handle the situation if either name-based lookup produces no results,
  # or, if the name-based lookup produces multiple, non-unique results

  if child_results_by_name.total_result_count == 0 || parent_results_by_name.total_result_count == 0 || \
        child_results_by_name.total_result_count > 1 || parent_results_by_name.total_result_count > 1
    if child_results_by_name.total_result_count == 0
      puts "Child PI Item #{child_pi_formatted_id}: #{child_pi_name} not found via Name query...Skipping"
    end
    if parent_results_by_name.total_result_count == 0
      puts "Parent PI Item #{parent_pi_formatted_id}: #{parent_pi_name} not found via Name query...Skipping"
    end
    if child_results_by_name.total_result_count > 1
      puts "Multiple Child PI Items Found with Name: #{child_pi_name} with name-based query."
      child_results_by_name.each do | this_child |
        puts "FormattedID: #{this_child.FormattedID}"
      end
    end
    if parent_results_by_name.total_result_count > 1
      puts "Multiple Parent PI Items Found with Name: #{parent_pi_name} with name-based query."
      parent_results_by_name.each do | this_parent |
        puts "FormattedID: #{this_parent.FormattedID}"
      end
    end

  # Finally, attempt to update the Child PI with the new Parent
  else
    begin

      if my_child_results.nil? then my_child_results = child_results_by_name end
      if my_parent_results.nil? then my_parent_results = parent_results_by_name end

      child_pi_item_toupdate = my_child_results.first()
      fields = {}
      fields["Parent"] = my_parent_results.first()
      rally_pi_updated = @rally.update(child_type_string, child_pi_item_toupdate.ObjectID, fields) #by ObjectID
      puts "Child PI Item #{child_pi_formatted_id}: #{child_pi_name} successfully updated parent to: "
      puts "   ==> Parent #{parent_pi_formatted_id}: #{parent_pi_name}"
    rescue => ex
      puts "Child PI Item #{child_pi_formatted_id}: #{child_pi_name} not updated due to error"
      puts ex.message
      puts ex.backtrace.join("\n")
      puts ex
    end
  end
end

begin

  #==================== Making a connection to Rally ====================
  config                  = {:base_url => $my_base_url}
  config[:username]       = $my_username
  config[:password]       = $my_password
  config[:headers]        = $my_headers #from RallyAPI::CustomHttpHeader.new()
  config[:workspace]      = $my_workspace
  config[:project]        = $my_project
  config[:version]        = $wsapi_version

  @rally = RallyAPI::RallyRestJson.new(config)

  input  = CSV.read($filename)

  header = input.first #ignores first line

  rows   = []

  (1...input.size).each { |i| rows << CSV::Row.new(header, input[i]) }

  rows.each do |row|
    assign_parent_portfolio_item(header, row)
  end
end