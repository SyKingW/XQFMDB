//
//  XQFMDB.h
//  XQFMDB
//
//  Created by ladystyle100 on 2017/8/15.
//  Copyright © 2017年 WangXQ. All rights reserved.
//

/**
 现在删除, 更新, 查询, 都是直接默认  and =, 并没有 or > < 这种, 后面有需求再写吧
 */

#import <Foundation/Foundation.h>


@class FMDatabase;
@class FMResultSet;

@interface XQFMDB : NSObject

/**
 删除数据库
 */
+ (void)delDB;

/**
 获取db, 在block结束之后会自动关闭db, 不要在不同线程去调用这个, 基本就不会出现db打开却不关闭问题
 */
+ (void)getDBWithResult:(void(^)(FMDatabase *db))result;

#pragma mark -- 表操作

/**
 创建表
 当表存在时, 会自动判断是否有这个字段, 没有, 则会自动创建
 
 @param tableName 表名
 @param autoincrementKey 自增键
 @param columnDic 表字段和类型, 格式如下
  @{
      @"字段名": @"字段类型", // 如果字段类型为@"", 那么会默认填text
   }
 字段类型: NSString -> text, NSInteger -> integer, NSData -> blob 大小写不区分
 - 文本： Text
 - 整形： Integer
 - 二进制数据: Blob
 - 浮点型： Real Float、Double
 - 布尔型： Boolean
 - 时间型： Time
 - 日期型： Date
 - 时间戳： TimeStamp
 */
+ (void)createWithTableName:(NSString *)tableName autoincrementKey:(NSString *)autoincrementKey columnDic:(NSDictionary *)columnDic;

/**
 创建表
 */
+ (void)createWithDB:(FMDatabase *)db tableName:(NSString *)tableName autoincrementKey:(NSString *)autoincrementKey columnDic:(NSDictionary *)columnDic;

/**
 创建表
 
 @param columnDic 要添加的字段类型
 @param modelClass 模型class, 转为要添加的字段 (不能获取到父属性)
 */
+ (void)createWithDB:(FMDatabase *)db tableName:(NSString *)tableName autoincrementKey:(NSString *)autoincrementKey columnDic:(NSDictionary *)columnDic modelClass:(Class)modelClass;

/**
 添加表字段名
 
 @param column 字段名
 @param type 类型
 */
+ (BOOL)alterAddColumnWithTabel:(NSString *)table column:(NSString *)column type:(NSString *)type;

/**
 获取某个表的所有列名

 @return 列名数组
 */
+ (NSArray <NSString *> *)getAllColumnNameWithTable:(NSString *)table;
/**
 获取某个表的所有列名
 */
+ (NSArray <NSString *> *)getAllColumnNameWithDB:(FMDatabase *)db table:(NSString *)table;

/**
 修改表的字段名, 查了一下, 好像不支持修改表字段, 但是有一个 sp_rename的, 这个好像是重命名的~

 @param oColumnName 原来的字段名
 @param nColumnName 新字段名
 */
//+ (BOOL)alterWithTabel:(NSString *)table oColumnName:(NSString *)oColumnName nColumnName:(NSString *)nColumnName;

/**
 修改表的字段名
 */
//+ (BOOL)alterWithDB:(FMDatabase *)db tabel:(NSString *)table oColumnName:(NSString *)oColumnName nColumnName:(NSString *)nColumnName;

/**
 删除表字段, sql暂不支持删除列操作
 */
+ (BOOL)alterRemoveColumnWithDB:(FMDatabase *)db tabel:(NSString *)table column:(NSString *)column;

#pragma mark -- 插入

/**
 插入

 @param table 表名
 @param dic @{@"对应创建时候的key": @"要插入的值"}
 */
+ (BOOL)insertWithTable:(NSString *)table dic:(NSDictionary *)dic;
/**
 插入
 同上
 */
+ (BOOL)insertWithDB:(FMDatabase *)db table:(NSString *)table dic:(NSDictionary *)dic;

/**
 获取带?号的sql字符串
 */
+ (NSString *)getInsertSqlFormatWithTable:(NSString *)table dic:(NSDictionary *)dic;

/**
 获取直接带值的sql字符串
 */
+ (NSString *)getInsertSqlContainValueFormatWithTable:(NSString *)table dic:(NSDictionary *)dic;

#pragma mark -- 删除

/**
 删除

 @param table 表名
 @param wDic 要删除的条件
 */
+ (BOOL)deleteWithTable:(NSString *)table wDic:(NSDictionary *)wDic;
/**
 删除
 同上
 */
+ (BOOL)deleteWithDb:(FMDatabase *)db table:(NSString *)table wDic:(NSDictionary *)wDic;

/**
 删除空值
 */
+ (BOOL)deleteNullWithTable:(NSString *)table key:(NSString *)key;

/// 删除
+ (BOOL)deleteWithDb:(FMDatabase *)db table:(NSString *)table where:(NSString *)where;

#pragma mark -- 更新

/**
 更新值
 
 @param wDic 条件
 @param sDic 改变的值
 */
+ (BOOL)updateWithDb:(FMDatabase *)db table:(NSString *)table wDic:(NSDictionary *)wDic sDic:(NSDictionary *)sDic;
/**
 更新值
 同上
 */
+ (BOOL)updateWithTable:(NSString *)table wDic:(NSDictionary *)wDic sDic:(NSDictionary *)sDic;

#pragma mark -- 查询

/**
 查询, 只有等于

 @param wDic 查询的字典
 */
+ (void)queryWithTable:(NSString *)table wDic:(NSDictionary *)wDic callback:(void(^)(FMDatabase *db, NSDictionary *dic))callback;
/**
 查询
 同上
 */
+ (void)queryWithDB:(FMDatabase *)db table:(NSString *)table wDic:(NSDictionary *)wDic callback:(void(^)(FMDatabase *db, NSDictionary *dic))callback;

/**
 查询, 并根据某个key升降序
 
 @param sortKey 升降序的key
 @param isAscending YES升序, NO降序
 */
+ (void)queryWithTable:(NSString *)table wDic:(NSDictionary *)wDic sortKey:(NSString *)sortKey isAscending:(BOOL)isAscending callback:(void(^)(FMDatabase *db, NSDictionary *dic))callback;
+ (void)queryWithDB:(FMDatabase *)db table:(NSString *)table wDic:(NSDictionary *)wDic sortKey:(NSString *)sortKey isAscending:(BOOL)isAscending normalCallback:(void(^)(FMDatabase *db, FMResultSet *resultSet))callback;

/**
 查询某个表有多少条数据

 @param wDic 要查询的值, 如不填, 则直接插整个表
 */
+ (int)queryRowsWithTable:(NSString *)table wDic:(NSDictionary *)wDic;

/**
 查询某个表有多少条数据

 @param where 要查询的值, 如不填, 则直接插整个表
 */
+ (int)queryRowsWithTable:(NSString *)table where:(NSString *)where;

/**
 查询
 
 @param where 条件
 */
+ (void)queryWithDB:(FMDatabase *)db table:(NSString *)table where:(NSString *)where callback:(void(^)(FMDatabase *db, NSDictionary *dic))callback;

/**
 查询
 
 @param where 条件
 */
+ (void)queryWithDB:(FMDatabase *)db table:(NSString *)table where:(NSString *)where normalCallback:(void(^)(FMDatabase *db, FMResultSet *resultSet))callback;

#pragma mark - 触发器

/// 删除触发器
/// @param triggerName 触发器名称
+ (void)deleteTriggerWithDB:(FMDatabase *)db triggerName:(NSString *)triggerName;

/// 创建触发器
/// @param triggerName 触发器名称
/// @param triggerOperation 触发动作 INSERT、DELETE 和 UPDATE
/// @param triggerKey 触发表里面的字段(如果是 @""，那么就是所有字段都触发)
/// @param triggerTable 触发的表名
/// @param executeTiming 执行时机, BEFORE 或 AFTER
/// @param executeCode 触发时，执行sql的语句(可多条语句)
/// 如果想取当前值，比如取 name 字段 new.name
/// 旧的值, old.name
/// @note 举两个例子
///
/// - 当有更新时就触发，并且更改 name 为 aaa: [XQFMDB createTriggerWithDB:db triggerName:@"triggerName" triggerOperation:@"UPDATE" triggerKey:@"" triggerTabel:@"tableName" executeTiming:@"BEFORE" executeCode:@"UPDATE school SET name = 'aaa';"];
/// - 当有 name 字段更新时触发，并且更改 count 和 imageName: [XQFMDB createTriggerWithDB:db triggerName:@"triggerName" triggerOperation:@"UPDATE" triggerKey:@"name" triggerTabel:@"tableName" executeTiming:@"BEFORE" executeCode:@"UPDATE school SET count = '11';UPDATE school SET imageName = 'aaa';"];
///
+ (void)createTriggerWithDB:(FMDatabase *)db
                triggerName:(NSString *)triggerName
           triggerOperation:(NSString *)triggerOperation
                 triggerKey:(NSString *)triggerKey
               triggerTabel:(NSString *)triggerTable
              executeTiming:(NSString *)executeTiming
                executeCode:(NSString *)executeCode;


/// 获取触发器列表
/// @param table 表名，如果传 @"", 则查询整个数据库的触发器
/// @param callback 返回数据如下 
/// {"sql":"CREATE TRIGGER nameUpdate BEFORE UPDATE OF name ON school BEGIN UPDATE school SET imageName = 'xxx1233777' where sId = old.sId; END","rootpage":0,"type":"trigger","name":"nameUpdate","tbl_name":"school"}
+ (void)queryTriggerListWithDB:(FMDatabase *)db tabel:(NSString *)table callback:(void(^)(NSDictionary *dic))callback;


@end

















