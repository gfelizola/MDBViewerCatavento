package
{
	import flash.data.SQLConnection;
	import flash.data.SQLStatement;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	
	[Bindable]
	public class Cache extends EventDispatcher
	{
		public static var instance:Cache = new Cache();
		
		private var sqlConnection:SQLConnection;
		
		public function Cache()
		{
			var file:File = File.applicationStorageDirectory.resolvePath("sqladmincache.db");
			var fileExists:Boolean = file.exists;
			sqlConnection = new SQLConnection();
			sqlConnection.open(file);
			if (!fileExists)
			{
				createTables();
			}
		}
		
		[Bindable(event="filesChange")]
		public function get files():Array
		{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = "SELECT * FROM files ORDER BY access DESC";
			stmt.execute();
			return stmt.getResult().data;
		}

		public function cacheFile(path:String):void
		{
			if (updateCachedFile(path) == 0)
			{
				addFileToCache(path);
			}
			dispatchEvent(new Event("filesChange"));
		}

		private function updateCachedFile(path:String):int
		{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = "UPDATE files SET access = " + new Date().time + " WHERE path = '"+path+"'";
			stmt.execute();
			return stmt.getResult().rowsAffected;
		}

		private function addFileToCache(path:String):int
		{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = "INSERT INTO files (path, access) VALUES ('"+path+"',"+new Date().time+")";
			stmt.execute();
			return stmt.getResult().rowsAffected;
		}

		[Bindable(event="statementsChange")]
		public function get statements():Array
		{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = "SELECT * FROM statements ORDER BY access DESC";
			stmt.execute();
			return stmt.getResult().data;
		}
		
		public function cacheStatement(sql:String):void
		{
			if (updateCachedStatement(sql) == 0)
			{
				addCachedStatement(sql);
			}
			dispatchEvent(new Event("statementsChange"));
		}
					
		private function updateCachedStatement(sql:String):int
		{
			var access:Number = new Date().time; 
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = "UPDATE statements SET access = " + new Date().time + " WHERE sql = '"+sql+"'";
			stmt.execute();
			return stmt.getResult().rowsAffected;
		}

		private function addCachedStatement(sql:String):int
		{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = "INSERT INTO statements (sql, access) VALUES ('"+sql+"'," + new Date().time + ")";
			stmt.execute();
			return stmt.getResult().rowsAffected;
		}

		private function createTables():void
		{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = "CREATE TABLE files (path longvarchar, access number)";
			stmt.execute();
			stmt.text = "CREATE TABLE statements (sql longvarchar, access number)";
			stmt.execute();
		}
		
		public function clearCache():void
		{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = "DELETE FROM statements";
			stmt.execute();
			dispatchEvent(new Event("statementsChange"));
		}

	}
}