//
//  XQFMDB.m
//  XQFMDB
//
//  Created by ladystyle100 on 2017/8/15.
//  Copyright © 2017年 WangXQ. All rights reserved.
//

#import "XQFMDB.h"
// runtime获取变量名称和变量值
#import <XQProjectTool/NSObject+XQViewOC.h>
#import <FMDB/FMDB.h>

@interface XQFMDB ()

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;

@end

@implementation XQFMDB

static XQFMDB *xq_fmdb_ = nil;

+ (instancetype)manager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        xq_fmdb_ = [XQFMDB new];
    });
    return xq_fmdb_;
}

- (FMDatabaseQueue *)dbQueue {
    if (!_dbQueue) {
        _dbQueue = [[FMDatabaseQueue alloc] initWithPath:[XQFMDB getPath]];
    }
    return _dbQueue;
}

#pragma mark -- 插入

+ (BOOL)insertWithTable:(NSString *)table dic:(NSDictionary *)dic {
    __block BOOL is = NO;
    [self getDBWithResult:^(FMDatabase *db) {
        is = [self insertWithDB:db table:table dic:dic];
    }];
    return is;
}

    // 插入设备到某网关
+ (BOOL)insertWithDB:(FMDatabase *)db table:(NSString *)table dic:(NSDictionary *)dic {
    /*
    NSString *keys = @"";
    NSString *values = @"";
    NSMutableArray *valueArr = [NSMutableArray array];
    for (int i = 0; i < dic.allKeys.count; i++) {
        NSString *key = dic.allKeys[i];
        id value = dic[key];
        [valueArr addObject:value];
        
        if (i == 0) {
            keys = key;
            values = @"?";
            continue;
        }
        
        keys = [NSString stringWithFormat:@"%@, %@", keys, key];
        values = [NSString stringWithFormat:@"%@,?", values];
    }
     */
    
    /*
    NSString *keys = [dic.allKeys componentsJoinedByString:@","];
    NSArray *valueArr = dic.allValues;
    
    NSMutableArray *valueMuArr = [NSMutableArray array];
    for (NSString *str in valueArr) {
        [valueMuArr addObject:@"?"];
    }
    NSString *values = [valueMuArr componentsJoinedByString:@","];
     */
    
    /*
    NSString *formatStr = [NSString stringWithFormat:@"insert into %@ (%@) values(%@)", table, keys, values];
    NSError *error = nil;
    BOOL result = [db executeUpdate:formatStr values:valueArr error:&error];
    if (error) {
        NSLog(@"插入失败 table = %@, dic = %@, error = %@", table, dic, error);
    }
     */
    
    
    NSString *formatStr = [self getInsertSqlContainValueFormatWithTable:table dic:dic];
    BOOL result = [db executeUpdate:formatStr];
    
    if (!result) {
        NSLog(@"插入失败 table = %@, dic = %@", table, dic);
    }
    
    return result;
}

// 获取带?号的sql字符串
+ (NSString *)getInsertSqlFormatWithTable:(NSString *)table dic:(NSDictionary *)dic {
    NSString *keys = [dic.allKeys componentsJoinedByString:@","];
    NSArray *valueArr = dic.allValues;
    
    NSMutableArray *valueMuArr = [NSMutableArray array];
    for (int i = 0; i < valueArr.count; i++) {
        [valueMuArr addObject:@"?"];
    }
    NSString *values = [valueMuArr componentsJoinedByString:@","];
    
    return [NSString stringWithFormat:@"insert into %@ (%@) values(%@)", table, keys, values];;
}

// 获取直接带值的sql字符串
+ (NSString *)getInsertSqlContainValueFormatWithTable:(NSString *)table dic:(NSDictionary *)dic {
    // 这个allKeys, 和allValues, 不知道真的是否相对, 反正目前测试是没问题的
    NSString *keys = [dic.allKeys componentsJoinedByString:@","];
    // 得加'', 不然有些数值, sql是分不出来的
    NSString *values = [dic.allValues componentsJoinedByString:@"','"];
    values = [NSString stringWithFormat:@"'%@'", values];
    return [NSString stringWithFormat:@"insert into %@ (%@) values(%@)", table, keys, values];;
}

// 根据类获取带?号sql字符串
+ (NSString *)getInsertSqlFormatWithTable:(NSString *)table xq_class:(Class)xq_class {
    return @"";
}

#pragma mark -- 删除
+ (BOOL)deleteWithTable:(NSString *)table wDic:(NSDictionary *)wDic {
    __block BOOL is = NO;
    [self getDBWithResult:^(FMDatabase *db) {
        is = [self deleteWithDb:db table:table wDic:wDic];
    }];
    return is;
}

+ (BOOL)deleteWithDb:(FMDatabase *)db table:(NSString *)table wDic:(NSDictionary *)wDic {
    NSString *str = @"";
    NSString *formatStr = @"";
    if (!wDic || [wDic allKeys].count == 0) {
        // 删除整个表
        formatStr = [NSString stringWithFormat:@"delete from %@", table];
    }else {
        str = [self getEqualStrWithWDic:wDic];
        formatStr = [NSString stringWithFormat:@"delete from %@ where %@", table, str];
    }
    
    BOOL result = [db executeUpdate:formatStr];
    if (!result) {
        NSLog(@"删除失败 table = %@, wDic = %@", table, wDic);
    }
    
    return result;
}

+ (BOOL)deleteNullWithTable:(NSString *)table key:(NSString *)key {
    __block BOOL is = NO;
    [self getDBWithResult:^(FMDatabase *db) {
        NSString *formatStr = [NSString stringWithFormat:@"delete from %@ where %@ is null", table, key];
        BOOL result = [db executeUpdate:formatStr];
        if (!result) {
            NSLog(@"删除失败 table = %@, key = %@", table, key);
        }
        
        is = result;
    }];
    return is;
}

#pragma mark -- 更新

+ (BOOL)updateWithTable:(NSString *)table wDic:(NSDictionary *)wDic sDic:(NSDictionary *)sDic {
    __block BOOL is = NO;
    [self getDBWithResult:^(FMDatabase *db) {
        is = [self updateWithDb:db table:table wDic:wDic sDic:sDic];
    }];
    return is;
}

+ (BOOL)updateWithDb:(FMDatabase *)db table:(NSString *)table wDic:(NSDictionary *)wDic sDic:(NSDictionary *)sDic {
    NSString *where = [self getEqualStrWithWDic:wDic];
    NSString *set = [self getSetStrWithSDic:sDic];
    NSString *formatStr = nil;
    
    if (where.length == 0) {
        formatStr = [NSString stringWithFormat:@"update %@ set %@", table, set];
    }else {
        formatStr = [NSString stringWithFormat:@"update %@ set %@ where %@", table, set, where];
    }
    
    BOOL result = [db executeUpdate:formatStr];
    if (!result) {
        NSLog(@"更新失败 table = %@, wDic = %@, sDic = %@", table, wDic, sDic);
    }
    return result;
}

#pragma mark -- 查询

+ (void)queryWithTable:(NSString *)table wDic:(NSDictionary *)wDic callback:(void(^)(FMDatabase *db, NSDictionary *dic))callback {
    [self getDBWithResult:^(FMDatabase *db) {
        [self queryWithDB:db table:table wDic:wDic callback:callback];
    }];
}

+ (void)queryWithDB:(FMDatabase *)db table:(NSString *)table wDic:(NSDictionary *)wDic callback:(void(^)(FMDatabase *db, NSDictionary *dic))callback {
    NSString *str = [self getEqualStrWithWDic:wDic];
    [self queryWithDB:db table:table where:str callback:callback];
}

+ (void)queryWithDB:(FMDatabase *)db table:(NSString *)table where:(NSString *)where callback:(void(^)(FMDatabase *db, NSDictionary *dic))callback {
    NSString *formatStr = [NSString stringWithFormat:@"select * from %@ where %@", table, where];
    if (where.length == 0) {
        formatStr = [NSString stringWithFormat:@"select * from %@", table];
    }
    FMResultSet *result = [db executeQuery:formatStr];
    while (result.next) {
            //获取设备基本信息
        NSDictionary *dic = [result resultDictionary];
        if (callback) {
            callback(db, dic);
        }
    }
}

+ (void)queryWithDB:(FMDatabase *)db table:(NSString *)table where:(NSString *)where normalCallback:(void(^)(FMDatabase *db, FMResultSet *resultSet))callback {
    NSString *formatStr = [NSString stringWithFormat:@"select * from %@ where %@", table, where];
    if (where.length == 0) {
        formatStr = [NSString stringWithFormat:@"select * from %@", table];
    }
    FMResultSet *resultSet = [db executeQuery:formatStr];
    if (callback) {
        callback(db, resultSet);
    }
}

+ (void)queryWithTable:(NSString *)table wDic:(NSDictionary *)wDic sortKey:(NSString *)sortKey isAscending:(BOOL)isAscending callback:(void(^)(FMDatabase *db, NSDictionary *dic))callback {
    [self getDBWithResult:^(FMDatabase *db) {
        [self queryWithDB:db table:table wDic:wDic sortKey:sortKey isAscending:isAscending callback:callback];
    }];
}

+ (void)queryWithDB:(FMDatabase *)db table:(NSString *)table wDic:(NSDictionary *)wDic sortKey:(NSString *)sortKey isAscending:(BOOL)isAscending callback:(void(^)(FMDatabase *db, NSDictionary *dic))callback {
    NSString *str = [self getEqualStrWithWDic:wDic];
    // 升序
    //SELECT * FROM t_student ORDER BY age;
    // 降序
    //SELECT * FROM t_student ORDER BY age DESC;
    
    NSString *formatStr = [NSString stringWithFormat:@"select * from %@ where %@ ORDER BY %@", table, str, sortKey];
    if (str.length == 0) {
        formatStr = [NSString stringWithFormat:@"select * from %@ ORDER BY %@", table, sortKey];
    }
    
    if (!isAscending) {
        formatStr = [NSString stringWithFormat:@"select * from %@ where %@ ORDER BY %@ DESC", table, str, sortKey];
    }
    FMResultSet *result = [db executeQuery:formatStr];
    while (result.next) {
            //获取设备基本信息
        NSDictionary *dic = [result resultDictionary];
        if (callback) {
            callback(db, dic);
        }
    }
}

+ (void)queryWithDB:(FMDatabase *)db table:(NSString *)table wDic:(NSDictionary *)wDic sortKey:(NSString *)sortKey isAscending:(BOOL)isAscending normalCallback:(void(^)(FMDatabase *db, FMResultSet *resultSet))callback {
    NSString *str = [self getEqualStrWithWDic:wDic];
    NSString *formatStr = [NSString stringWithFormat:@"select * from %@ where %@ ORDER BY %@", table, str, sortKey];
    if (!isAscending) {
        formatStr = [NSString stringWithFormat:@"select * from %@ where %@ ORDER BY %@ DESC", table, str, sortKey];
    }
    FMResultSet *resultSet = [db executeQuery:formatStr];
    if (callback) {
        callback(db, resultSet);
    }
}

+ (int)queryRowsWithTable:(NSString *)table wDic:(NSDictionary *)wDic {
    __block int rows = -1;
    NSString *str = [self getEqualStrWithWDic:wDic];
    [self getDBWithResult:^(FMDatabase *db) {
        NSString *format = [NSString stringWithFormat:@"select count(*) from %@", table];
        if (str.length != 0) {
            format = [NSString stringWithFormat:@"select count(*) from %@ where %@", table, str];
        }
        rows = [db intForQuery:format];
    }];
    return rows;
}

#pragma mark -- 表

// 创表
+ (void)createWithTableName:(NSString *)tableName autoincrementKey:(NSString *)autoincrementKey columnDic:(NSDictionary *)columnDic {
    [self getDBWithResult:^(FMDatabase *db) {
        [self createWithDB:db tableName:tableName autoincrementKey:autoincrementKey columnDic:columnDic];
    }];
}

// 创表
+ (void)createWithDB:(FMDatabase *)db tableName:(NSString *)tableName autoincrementKey:(NSString *)autoincrementKey columnDic:(NSDictionary *)columnDic modelClass:(Class)modelClass {
    NSMutableDictionary *dic = @{}.mutableCopy;
    // 获取这个类的属性
//    NSArray <XQRuntimeModel *> *arr = [self xq_viewPropertyWithObj:nil class:modelClass];
    NSArray <XQRuntimeModel *> *arr = [self xq_viewAllPropertyWithObj:nil class:modelClass];
    for (int i = 0; i < arr.count; i++) {
        XQRuntimeModel *model = arr[i];
        //            文本： Text
        //            整形： Integer
        //            二进制数据: Blob
        //            浮点型： Real Float、Double
        //            布尔型： Boolean
        //            时间型： Time
        //            日期型： Date
        //            时间戳： TimeStamp
        // 根据不同类型, 存储到本地的类型也不同
        NSString *type = model.xq_encoding;
        if ([type containsString:@"NSString"]) {
            [dic addEntriesFromDictionary:@{model.xq_name: @"text"}];
            
        }else if ([type isEqualToString:@"q"] || [type isEqualToString:@"i"] || [type isEqualToString:@"s"] || [type isEqualToString:@"l"] || [type isEqualToString:@"S"] || [type isEqualToString:@"L"] || [type isEqualToString:@"Q"]) {
            
            [dic addEntriesFromDictionary:@{model.xq_name: @"integer"}];
            
        }else if ([type isEqualToString:@"f"] || [type isEqualToString:@"d"] || [type isEqualToString:@"q"]) {
            
            [dic addEntriesFromDictionary:@{model.xq_name: @"double"}];
            
        }else if ( [type isEqualToString:@"B"]) {
            
            [dic addEntriesFromDictionary:@{model.xq_name: @"Boolean"}];
            
        }else {
            [dic addEntriesFromDictionary:@{model.xq_name: @"text"}];
            
        }
    }
    
    
    NSMutableDictionary *muDic = [NSMutableDictionary dictionary];
    [muDic addEntriesFromDictionary:columnDic];
    [muDic addEntriesFromDictionary:dic];
    
    [self createWithDB:db tableName:tableName autoincrementKey:autoincrementKey columnDic:muDic];
}

// 创表
+ (void)createWithDB:(FMDatabase *)db tableName:(NSString *)tableName autoincrementKey:(NSString *)autoincrementKey columnDic:(NSDictionary *)columnDic {
    if (tableName.length == 0 || [columnDic allKeys].count == 0 || autoincrementKey.length == 0) {
        NSLog(@"param error");
        return;
    }
    
        // 在这判断是否创建了表, 没创建则创建表
    if (![db tableExists:tableName]) {
        NSString *columnNamesStr = @"";
        for (int i = 0; i < columnDic.allKeys.count; i++) {
            NSString *key = columnDic.allKeys[i];
            NSString *type = columnDic[key];
            
            if (key.length == 0) {
                continue;
            }
            
            if (columnNamesStr.length == 0) {
                if (type.length == 0) {
                    columnNamesStr = [NSString stringWithFormat:@"%@ text", key];
                }else {
                    columnNamesStr = [NSString stringWithFormat:@"%@ %@", key, type];
                }
                continue;
            }
            
            if (type.length == 0) {
                columnNamesStr = [NSString stringWithFormat:@"%@, %@ text", columnNamesStr, key];
            }else {
                columnNamesStr = [NSString stringWithFormat:@"%@, %@ %@", columnNamesStr, key, type];
            }
        }
        // createID 是自增id, 唯一标志,  IF NOT EXISTS是判断表是否存在
        NSString *format = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ INTEGER PRIMARY KEY AUTOINCREMENT, %@);", tableName, autoincrementKey, columnNamesStr];
        if (![db executeUpdate:format]) {
            NSLog(@"创建表失败 %@", tableName);
        }else {
            NSLog(@"创表成功 %@", tableName);
        }
        
    }else {
        NSLog(@"已存在表 %@", tableName);
        for (int i = 0; i < columnDic.allKeys.count; i++) {
            NSString *key = columnDic.allKeys[i];
            NSString *type = columnDic[key];
            [self alterAddColumnWithDB:db tabel:tableName column:key type:type];
        }
    }
}

    // 添加表字段
+ (BOOL)alterAddColumnWithTabel:(NSString *)table column:(NSString *)column type:(NSString *)type {
    __block BOOL is = NO;
    [self getDBWithResult:^(FMDatabase *db) {
        is = [self alterAddColumnWithDB:db tabel:table column:column type:type];
    }];
    return is;
}

    // 添加表字段
+ (BOOL)alterAddColumnWithDB:(FMDatabase *)db tabel:(NSString *)table column:(NSString *)column type:(NSString *)type {
    BOOL is = NO;
    if (![db tableExists:table]) {
        NSLog(@"表不存在");
        return is;
    }
    
        // 如不存在, 则添加
    if (![db columnExists:column inTableWithName:table]) {
        if (type.length == 0) {
            type = @"text";
        }
            //alter table 表名 ADD 字段 类型 NOT NULL Default 0
        NSString *format = [NSString stringWithFormat:@"alter table %@ ADD '%@' %@", table, column, type];
        is = [db executeUpdate:format];
        if (is) {
            NSLog(@"添加字段成功 %@ %@", column, type);
        }
    }else {
        //NSLog(@"已存在字段");
    }
    return is;
}

// 获取表的所有列
+ (NSArray <NSString *> *)getAllColumnNameWithTable:(NSString *)table {
    __block NSArray *arr = nil;
    [self getDBWithResult:^(FMDatabase *db) {
        arr = [self getAllColumnNameWithDB:db table:table];
    }];
    return arr;
}

// 获取表的所有列
+ (NSArray <NSString *> *)getAllColumnNameWithDB:(FMDatabase *)db table:(NSString *)table {
    if (![db tableExists:table]) {
        NSLog(@"表不存在");
        return nil;
    }
    
    FMResultSet *result = [db getTableSchema:table];
    NSMutableArray *nameArr = [NSMutableArray array];
    while ([result next]) {
        [nameArr addObject:[result stringForColumn:@"name"]];
    }
    return nameArr.copy;
}

// 修改字段名称
+ (BOOL)alterWithTabel:(NSString *)table oColumnName:(NSString *)oColumnName nColumnName:(NSString *)nColumnName {
    __block BOOL is = NO;
    [self getDBWithResult:^(FMDatabase *db) {
        is = [self alterWithDB:db tabel:table oColumnName:oColumnName nColumnName:nColumnName];
    }];
    return is;
}

    // 修改字段名称
+ (BOOL)alterWithDB:(FMDatabase *)db tabel:(NSString *)table oColumnName:(NSString *)oColumnName nColumnName:(NSString *)nColumnName {
    BOOL is = NO;
    if (![db tableExists:table]) {
        NSLog(@"表不存在");
        return is;
    }
    
        // 判断是否存在这个字段, 存在则去改变
    if ([db columnExists:oColumnName inTableWithName:table]) {
//        ALTER TABLE "table_name"
//        Change "column 1" "column 2" ["Data Type"];
        
        //alter table %@ rename COLUMN '%@' to '%@'
        NSString *format = [NSString stringWithFormat:@"alter table %@ rename column %@ to %@", table, oColumnName, nColumnName];
        is = [db executeUpdate:format];
        
        if (is) {
            NSLog(@"修改字段成功");
        }
    }else {
        NSLog(@"不存在该字段");
    }
    return is;
}

// 删除表字段
+ (BOOL)alterRemoveColumnWithDB:(FMDatabase *)db tabel:(NSString *)table column:(NSString *)column {
    BOOL is = NO;
    if (![db tableExists:table]) {
        NSLog(@"表不存在");
        return is;
    }
    
        // 存在, 则删除
    if ([db columnExists:column inTableWithName:table]) {
        //ALTER TABLE [表名] DROP COLUMN [字段名]
        NSString *format = [NSString stringWithFormat:@"ALTER TABLE %@ DROP COLUMN %@", table, column];
        is = [db executeUpdate:format];
        if (is) {
            NSLog(@"删除字段成功");
        }else {
            NSLog(@"删除字段失败");
        }
    }else {
        NSLog(@"不存在字段");
    }
    
    return is;
}

#pragma mark -- 获取db

/** 传入路径获取db */
//+ (void)getDBWithPath:(NSString *)path result:(void(^)(FMDatabase *db))result {
//    FMDatabase *db = [FMDatabase databaseWithPath:path];
//
//    if (![db open]) {
//        NSLog(@"打开数据库失败");
//        return;
//    }
//
//    if (result) {
//        result(db);
//    }
//
//    if (![db close]) {
//        NSLog(@"关闭数据库失败");
//    }
//}

+ (void)getDBWithResult:(void (^)(FMDatabase *))result {
    
    // 如果不想在主线程操作fmdb, 可以在这里, 让在子线程使用queue, 并返回block, 这样, db, 就都在子线程操作了
    // 这样的话, 就要注意, 不能在block内, 再次调用这个方法, 再次去获得db
    // 看了一下内部操作, 其实就是用 dispatch_sync 到他自己的线程去取 db, 再返出来, 这样的话，就不会出现什么多线程操作有问题了
    [[XQFMDB manager].dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        if (!db) {
            return ;
        }
        
        // inDatabase 里面已经打开了
//        if (![db open]) {
//            NSLog(@"打开数据库失败");
//            return;
//        }
        
        if (result) {
            result(db);
        }
        
        if (![db close]) {
            NSLog(@"关闭数据库失败");
        }
        
    }];
}

+ (void)delDB {
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:[self getPath]]) {
        NSLog(@"数据库存在");
        NSError *error = nil;
        [manager removeItemAtPath:[self getPath] error:&error];
        if (error) {
            NSLog(@"删除数据库失败 %@", error);
        }else {
            NSLog(@"删除数据库成功");
        }
    }else {
        NSLog(@"数据库不存在");
    }
}

+ (NSString *)getPath {
    // 这个, 可能会导致系统删除缓存文件夹, 然后本地数据消失...所以这个不能存cache
    // 获取Documents目录路径
    NSString *docDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *docPath = [docDir stringByAppendingPathComponent:@"xq_db"];
    
    NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    path = [path stringByAppendingPathComponent:@"xq_db"];
    
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (isExist) {
        // 存在数据库, 则移动
        NSError *error = nil;
        [[NSFileManager defaultManager] moveItemAtPath:path toPath:docPath error:&error];
        if (error) {
            NSLog(@"移动数据库失败");
            return path;
        }else {
            NSLog(@"移动数据库成功");
        }
    }
    
    return docPath;
}

// 只会获得=的str
+ (NSString *)getEqualStrWithWDic:(NSDictionary *)wDic {
    NSString *str = @"";
    if (!wDic || [wDic allKeys].count == 0) {
        return str;
    }
    for (int i = 0; i < wDic.allKeys.count; i++) {
        NSString *key = wDic.allKeys[i];
        id value = wDic[key];
        if (i == 0) {
            str = [NSString stringWithFormat:@"%@ = '%@'", key, value];
            continue;
        }
        
        str = [NSString stringWithFormat:@"%@ and %@ = '%@'", str, key, value];
    }
    return str;
}

// 获取set的字符串
+ (NSString *)getSetStrWithSDic:(NSDictionary *)sDic {
    NSString *str = @"";
    if (!sDic) {
        return str;
    }
    
    for (int i = 0; i < sDic.allKeys.count; i++) {
        NSString *key = sDic.allKeys[i];
        id value = sDic[key];
        if (i == 0) {
            str = [NSString stringWithFormat:@"%@ = '%@'", key, value];
            continue;
        }
        
        str = [NSString stringWithFormat:@"%@, %@ = '%@'", str, key, value];
    }
    
    return str;
}


@end




/**
 http://www.jianshu.com/p/7a7767e6c9ac SQL基本使用语句
 tableName:表名  where:条件
 
 参数类型：NSString -> text, NSInteger -> integer, NSData -> blob
 传入时，字符串和NSData需加''：'NSString', 'NSData', NSInteger
 到时候新建和插入，估计值都是固定的，所以到时候得改（不固定的方法，实现太麻烦）
 
 where: and 并且, or 或
 判断值: =等于, <小于, >大于, <>不等于
 key in ('%@', '%@', '%@', '%@') 这个是某个key, 在这几个选项中, 就表示满足需求
 
 SELECT * FROM table ORDER BY key;  -- 将查询结果按照分数从小到大排序
 SELECT * FROM table ORDER BY key desc; -- 将查询结果按照分数从大到小排序
 
 SELECT * FROM t_student LIMIT 数字1,数字2;
 - 跳过前9条数据，再查询3条数据
 SELECT * FROM t_student LIMIT 9, 3;
 - 跳过0条数据,取5条数据
 SELECT * FROM t_student LIMIT 5;
 
 - 默升序排序
 SELECT * FROM t_student ORDER BY age;
 - 降序
 SELECT * FROM t_student ORDER BY age DESC;
 - 按照年龄升序排序,如果年龄相同,按照名字的降序排列
 SELECT * FROM t_student ORDER BY age,name DESC;
 
 - 计算一共多少列
 SELECT count(*) FROM t_student;
 - 计算某一个列个数
 SELECT count(age) FROM t_student;
 
 重命名表：(Access 重命名表，请参考文章：在Access数据库中重命名表)
 sp_rename \'表名\', \'新表名\', \'OBJECT\'
 
 新建约束：
 ALTER TABLE [表名] ADD CONSTRAINT 约束名 CHECK ([约束字段] <= \'2000-1-1\')
 删除约束：
 ALTER TABLE [表名] DROP CONSTRAINT 约束名
 
 新建默认值
 ALTER TABLE [表名] ADD CONSTRAINT 默认值名 DEFAULT \'51WINDOWS.NET\' FOR [字段名]
 删除默认值
 ALTER TABLE [表名] DROP CONSTRAINT 默认值名
 
 事务操作, 如果操作不成功, 即可以回滚
 [jkDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
 // YES代表回滚, 如果在这之中操作失败, 或者错误, 则直接回滚就行
 *rollback = YES;
 }];
 
 
 创表
 CREATE TABLE IF NOT EXISTS %@ (xqCreateID INTEGER PRIMARY KEY AUTOINCREMENT, phone text, udid text, user_phone text, email text, user_name text, img text)
 
 查询
 NSString *queryFormat = [NSString stringWithFormat:@"SELECT * FROM %@", tableName];
 NSString *queryFormat = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@;", tableName, where];
 
 更新
 NSString *updateFormat = [NSString stringWithFormat:@"UPDATE %@ SET %@;", tableName, parameter];
 NSString *updateFormat = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@;", tableName, parameter, where];
 
 插入
 NSString *insterFormat = [NSString stringWithFormat:@"INSERT INTO %@ (name, age) VALUES (?, ?);", tableName];
 
 删除
 NSString *deleteFormat = [NSString stringWithFormat:@"DELETE FROM %@", tableName];
 NSString *deleteFormat = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@", tableName, where];
 
 
 复制一列到另一列, 两列的属性必须相同, 下面是, 表1.name = 表2.nick (也可以 表1.name = 表1.nick)
 update 表1 set name = 表2.nick where 表1.id = 表2.id
 
 
 
 5、注意，这个mark一下，参数为字典，写法变了，并且插入字段必须与字典key相对应
 - (BOOL)executeUpdate:(NSString*)sql withParameterDictionary:(NSDictionary *)arguments;
 
 
 
 关联表查询
 
 也可以这样直接插入字典
 NSDictionary *testDict = @{ @"id" : @14, @"name" : @"ly", @"age" : @15 };
 [db executeUpdate:@"INSERT INTO usertable VALUES(:id, :name, :age)" withParameterDictionary:testDict];
 这样插入数组
 [db executeUpdate:@"INSERT INTO usertable VALUES (?, ? , ?)" withArgumentsInArray:@[@2, @"yanghuixue", @26]];
 
 
 // 两表关联
 NSString *qFormat = @""
 "SELECT * "
 "FROM table1 "
 
 //        "INNER JOIN table2 ON table1.obj_id = table2.device_id " // 两表关联
 //        "JOIN table2 ON table1.obj_id = table2.device_id " // 两表关联 JOIN == INNER JOIN
 
 //        "LEFT JOIN table2 ON table1.obj_id = table2.device_id " // 没有匹配, 也返回左表的数据
 //        "RIGHT JOIN table2 ON table1.obj_id = table2.device_id " // 没有匹配, 也返回右表的数据 ??? 
 //        "FULL JOIN table2 ON table1.obj_id = table2.device_id " // 只要其中一个表中存在匹配，就返回行 ???
 "";
 
 
 // 多表关联
 // 但是这样的话, 就会变成, 要先等于 device_id 然后才查 scene_id, 这样就不符合初衷
 // 这个符合用 LEFT JOIN , 然后一次查出来多个表组合的内容有什么
 NSString *qFormat = @""
 "SELECT * "
 "FROM "
 
 "(homePageObjs JOIN devices ON homePageObjs.obj_id = devices.device_id) "
 "JOIN scenes ON homePageObjs.obj_id = scenes.scene_id"
 
 "";
 
 格式:
 三表
 SELECT 查询内容 FROM (JOIN 表2 ON 表1.字段 = 表2.字段 ) JOIN 表3 ON 表1.字段 = 表3.字段
 四表
 SELECT 查询内容 FROM ((JOIN 表2 ON 表1.字段 = 表2.字段 ) JOIN 表3 ON 表1.字段 = 表3.字段 ) JOIN 表4 ON 表1.字段 = 表4.字段
 其实就是依次循环下去就行了
 

 UNION 联合指令, 相当于把多条 指令联合, 一次性查出来
 坑1: 不同表, 字段会以第一个为主, 所以表字段都得重设一下. (表1字段1 device 表2字段1 scene, 那么查出来, 字段都是 device ....)
 坑2: 表列数不同, 要自己添加 null xxx 字段上去, 补充列数
 UN查询的不同表 列数不同, 是不行的. 不过可以tye
 
NSString *qFormat = @""
// 重设字段, 并且 null 补充字段, 增加 xq_type 识别这个是表1, 还是表2查出来的
"SELECT devices.device_id AS d_id, devices.device_name AS d_name, null d_img_code, 'device' xq_type "
"FROM homePageObjs JOIN devices ON homePageObjs.obj_id = devices.device_id "

"UNION ALL " // UNION 过滤相同内容, UNION ALL 直接给出所有结果

"SELECT scenes.scene_id AS d_id, scenes.scene_name AS d_name, scenes.scene_img_code AS d_img_code, 'scene' xq_type "
"FROM homePageObjs JOIN scenes ON homePageObjs.obj_id = scenes.scene_id "

"";
 
 key AS 别名 是别名某个字段
 
 
 */










