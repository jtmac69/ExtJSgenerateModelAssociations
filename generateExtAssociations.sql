/**************************************************************************************

	FILE

		generateExtAssociations.sql
			
	DESCRIPTION
	
		Transact-SQL (MS) Function to generate the 'associations' model configuration array JSON text used 
		within a Sencha ExtJS or Touch Model definition for a given table object
		
		Basically, uses the MS-SQL database information to generate proper association types:
			- hasOne
			- belongsTo
			- hasMany
			
			The output assumes that you are using a Sencha MVC model definitions to generate fully-qualified model names (e.g., MyApp.model.location)
			
		Only works on table objects but can be used to generate the associations for a model based on a view for the table(s)
		referenced oin the view.
		
	PARAMETERS

		name: @tableName varchar
		desc: the SQL table
		vals: existing object in DB
	 default: none; required

		name: @appName varchar
		desc: the namespace of the app (prepended to the model references)
		vals: any
	 default: 'MyApp'

	OUTPUT
		name: @associations varchar
		desc: the final JS string which can be copied/pased into a model definition .js file for use in Sencha Apps
	
	HISTORY
	
		25-Jul-2013		JT McGibbon
			Initial implementation.	
			
*************************************************************************************/

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[generateExtAssociations]') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	drop function [dbo].[generateExtAssociations]
go

create function dbo.generateExtAssociations( 
	@tableName	varchar(255), 
	@appName	varchar(255) = 'MyApp' 
) returns varchar(max) as 
begin
	declare @assocString as varchar(max)
	declare @assocItem as varchar(512)
	declare @assocType as varchar(255)
	declare @modelName as varchar(255)
	declare @assocFK as varchar(255)
	declare @assocPK as varchar(255)
	declare @haveFirstAssoc as bit
	declare @ccName varchar(255)

	set @assocString = ''
	set @assocItem = ''
	set @haveFirstAssoc = 0

	declare assoc_curs cursor for
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
		
	open assoc_curs

	if ( @@CURSOR_ROWS != 0 ) begin

		set @assocString = 'associations: ['
		
		fetch next from assoc_curs into
			@assocType,
			@modelName,
			@assocFK,
			@assocPK
			
		while ( @@fetch_status = 0 ) begin
		
			if (@haveFirstAssoc = 1) set @assocString = @assocString+char(13)+char(10)+','+char(13)+char(10)
			set @ccName = upper(left(@modelName,1))+lower(right(@modelName,len(@modelName)-1))
			set @assocItem = 
				case @assocType
					when 'belongsTo' then 
						'{type: "belongsTo",'+char(13)+char(10)+
						'model: "'+@appName+'.model.'+@modelName+'",'+char(13)+char(10)+
						'foreignKey: "'+@assocFK+'",'+char(13)+char(10)+
						'primaryKey: "'+@assocPK+'"'+char(13)+char(10)+'}'
					when 'hasOne' then 
						'{type: "hasOne",'+char(13)+char(10)+
						'model: "'+@appName+'.model.'+@modelName+'",'+char(13)+char(10)+
						'foreignKey: "'+@assocFK+'",'+char(13)+char(10)+
						'name: "'+@ccName+'",'+char(13)+char(10)+
						'primaryKey: "'+@assocPK+'",'+char(13)+char(10)+
						'associationKey: "the'+@ccName+'",'+char(13)+char(10)+
						'getterName: "get'+@ccName+'",'+char(13)+char(10)+
						'setterName: "set'+@ccName+'"}'+char(13)+char(10)
					when 'hasMany' then 
						'{type: "hasMany",'+char(13)+char(10)+
						'model: "'+@appName+'.model.'+@modelName+'",'+char(13)+char(10)+
						'foreignKey: "'+@assocFK+'",'+char(13)+char(10)+
						'name: "'+@ccName+'s",'+char(13)+char(10)+
						'associationKey: "'+@modelName+'s",'+char(13)+char(10)+
						'primaryKey: "'+@assocPK+'"}'+char(13)+char(10)
				end
			set @assocString = @assocString+@assocItem
			set @haveFirstAssoc = 1
			
			fetch next from assoc_curs into
				@assocType,
				@modelName,
				@assocFK,
				@assocPK
		end
		set @assocString = @assocString+']'+char(13)+char(10)
	end

	close assoc_curs
	deallocate assoc_curs
	return @assocString
end
