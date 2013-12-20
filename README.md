## generateExtAssociations ##

A simple transact SQL (MS SQL) function for generating the Javscript for well-formed Sencha ExtJS and Touch Model association array config.

**generateExtAssociations** works for tables.

### Features: ###

- Accurately maps SQL relationships between the target table and other tables with 1-to-1, 0-to-1 and 1-to-many relationships.
- Allows for specification of the ExtJS or Touch application namespace
- Appropriately generates the Sencha association type (hasOne, belongsTo or hasMany) for each association.
- Automatically fills in the appropriate association configs for each association type (primary key name, foriegn key, etc.)

To use, 

1. simply download the SQL generateExtAssociations script and execute to create the function.
2. Within SQL, exec the function (see example SQL in repo)

The Function requires the 1st parameter (string) of the DB object (table or view) name and either a value or keyword 'default' for the app Name space (string) -- (defaults to 'MyApp')

**Notes:**  


1. Included is the base query (in getAssociations.sql) which simply outputs a table of the relationship type, related table, primary key and foreign key if you wish to not generate the full boat with the function.
2. If you have a model definition based on a view and want the associations, you can run the function on the table(s) the view is based upon and copy/paste as needed to the model definition for the view.

