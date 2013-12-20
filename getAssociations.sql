/**************************************************************************************
 
	FILE
 
		getAssociations.sql
			
	DESCRIPTION
	
		Transact SQL (MS) sql snippet to genreate a list of the
		relationships and their types to a given table object
		
	To Use: 
	  Set @tableName = '<name of the table you want the information about>'
	  run the script
	
		
***************************************************************************************/
 declare @tableName varchar(255)
  
  set @tableName = 'location'
  
	select a.type,a.model,a.foreignKey,a.primaryKey from
	(SELECT
	'hasMany' as type,
	lower(FK.TABLE_NAME) as model,
	lower(CU.COLUMN_NAME) as foreignKey,
	--PK_Table = PK.TABLE_NAME,
	--PK_Column = PT.COLUMN_NAME,
	lower((select c.name 
	from sys.index_columns ic 
		join sys.objects o on o.object_id=ic.object_id
		join sys.indexes i on ic.index_id=i.index_id and i.object_id = o.object_id
		join sys.columns c on c.column_id=ic.column_id and c.object_id = o.object_id
	where 
		o.name = FK.TABLE_NAME and 
		is_primary_key = 1)) as primaryKey
	FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS C
	INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS FK ON C.CONSTRAINT_NAME = FK.CONSTRAINT_NAME
	INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS PK ON C.UNIQUE_CONSTRAINT_NAME = PK.CONSTRAINT_NAME
	INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE CU ON C.CONSTRAINT_NAME = CU.CONSTRAINT_NAME
	INNER JOIN (
	SELECT i1.TABLE_NAME, i2.COLUMN_NAME
	FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS i1
	INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE i2 ON i1.CONSTRAINT_NAME = i2.CONSTRAINT_NAME
	WHERE i1.CONSTRAINT_TYPE = 'PRIMARY KEY'
	) PT ON PT.TABLE_NAME = PK.TABLE_NAME
	WHERE PK.TABLE_NAME=@tableName
	UNION
	SELECT
	case 
		when cu.column_name = (select c.name 
	from sys.index_columns ic 
		join sys.objects o on o.object_id=ic.object_id
		join sys.indexes i on ic.index_id=i.index_id and i.object_id = o.object_id
		join sys.columns c on c.column_id=ic.column_id and c.object_id = o.object_id
	where 
		o.name = FK.TABLE_NAME and 
		is_primary_key = 1) then 'hasOne'
		else 'belongsTo'
	end  as type,
	lower(PK.TABLE_NAME) as model,
	lower(CU.COLUMN_NAME) as foreignKey,
	lower(PT.COLUMN_NAME) as primaryKey
	FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS C
	INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS FK ON C.CONSTRAINT_NAME = FK.CONSTRAINT_NAME
	INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS PK ON C.UNIQUE_CONSTRAINT_NAME = PK.CONSTRAINT_NAME
	INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE CU ON C.CONSTRAINT_NAME = CU.CONSTRAINT_NAME
	INNER JOIN (
	SELECT i1.TABLE_NAME, i2.COLUMN_NAME
	FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS i1
	INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE i2 ON i1.CONSTRAINT_NAME = i2.CONSTRAINT_NAME
	WHERE i1.CONSTRAINT_TYPE = 'PRIMARY KEY'
	) PT ON PT.TABLE_NAME = PK.TABLE_NAME
	WHERE FK.TABLE_NAME=@tableName
	) as a
	---- optional:
	ORDER BY
	1,2,3
