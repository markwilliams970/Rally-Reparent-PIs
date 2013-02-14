Rally-Reparent-PIs
==================

The parent_portfolio_items.rb script is a tool to help Rally users bulk
re-parent Portfolio Items to higher-level Portfolio Items in the PI Hierarchy.
I.E. Re-parent Features to Initiatives

parent_portfolio_items.rb requires:
- Ruby 1.9.3
- rally_api 0.9.1 or higher
- You can install rally_api and dependent gems by using:
- gem install rally_api

The tool takes a set of Portfolio Items formatted in a CSV
and performs the following functions:
- Bulk re-parents Portfolio Items to specified Portfolio Items at the next higher level of PI hierarchy