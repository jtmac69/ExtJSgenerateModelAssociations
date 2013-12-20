/*	The Function requires 1st param (string) of the DB object (table) name
*	and either values or keyword 'default' for 2nd
*	app Name space (string) -- defaults to 'MyApp'
*/
-- Example with all special values for the invoice table
select dbo.generateExtModel('invoice', 'PFNApp') as jsstring
go
-- Example with all default values for the invoice table
select dbo.generateExtModel('invoice', default) as jsstring
go
