//
//  NCUserInfoCacheDBHelper.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCUserInfoCacheDBHelper.h"

int const NCUIStorageVersion = 6;

@interface NCUserInfoCacheDBHelper ()

@property (nonatomic, strong) NCFMDatabase *workingDB;

@end

@implementation NCUserInfoCacheDBHelper

- (instancetype)initWithPath:(NSString *)storagePath {
    self = [super init];
    if (self) {
        self.workingDB = [[NCFMDatabase alloc] initWithPath:storagePath];
        [self createDBTableIfNeed];
    }
    return self;
}

- (void)createDBTableIfNeed {
    if ([self.workingDB open]) {
        [self updateDBVersionIfNeed:NCUIStorageVersion];
        [self.workingDB executeUpdate:@"CREATE TABLE IF NOT EXISTS USER_INFO(user_id TEXT PRIMARY "
                                      @"KEY, name TEXT, alias TEXT, "
                                      @"avatar_url TEXT, extra TEXT)"];
        [self.workingDB
            executeUpdate:
                @"CREATE TABLE IF NOT EXISTS CONVERSATION_USER_INFO(conversation_type INTEGER, "
                @"target_id TEXT, user_id TEXT, name TEXT, alias TEXT, avatar_url TEXT, extra "
                @"TEXT,  PRIMARY "
                @"KEY(conversation_type, target_id, user_id))"];
        [self.workingDB
            executeUpdate:@"CREATE TABLE IF NOT EXISTS CONVERSATION_INFO(conversation_type "
                          @"INTEGER, target_id TEXT, "
                          @"name TEXT, avatar_url TEXT, extra TEXT, PRIMARY KEY(conversation_type, "
                          @"target_id))"];
    } else {
        self.workingDB = nil;
    }
}

- (void)updateDBVersionIfNeed:(int)version {
    if ([self.workingDB open]) {
        [self.workingDB
            executeUpdate:@"CREATE TABLE IF NOT EXISTS VERSION(version INTEGER PRIMARY KEY)"];
        int oldVersion = 0;
        NCFMResultSet *resultSet = [self.workingDB executeQuery:@"SELECT * FROM VERSION"];
        if ([resultSet next]) {
            oldVersion = [resultSet intForColumn:@"version"];
        }
        [resultSet close];
        if (oldVersion < version) {
            // Rebuild the table for the avatar_url rename without migrating the old column data.
            if (oldVersion > 0) {
                [self.workingDB executeUpdate:@"DROP TABLE IF EXISTS USER_INFO"];
                [self.workingDB executeUpdate:@"DROP TABLE IF EXISTS CONVERSATION_USER_INFO"];
                [self.workingDB executeUpdate:@"DROP TABLE IF EXISTS CONVERSATION_INFO"];
            }
            [self.workingDB executeUpdate:@"DELETE FROM VERSION"];
            [self.workingDB
                executeUpdate:@"INSERT OR REPLACE INTO VERSION (version) VALUES(?)", @(version)];
        }
    }
}

- (void)closeDBIfNeed {
    if (self.workingDB) {
        [self.workingDB close];
        self.workingDB = nil;
    }
}

- (void)dealloc {
    [self closeDBIfNeed];
}

#pragma mark - ConversationInfo DB

- (NCChannelInfo *)selectConversationInfoFromDB:(NCChannelType)channelType
                                      channelId:(NSString *)channelId {
    if ([self.workingDB open]) {
        NCFMResultSet *resultSet = [self.workingDB
            executeQuery:
                @"SELECT * FROM CONVERSATION_INFO WHERE conversation_type = ? AND target_id = ?",
                @(channelType), channelId];
        if ([resultSet next]) {
            NCChannelInfo *dbConversationInfo = [[NCChannelInfo alloc] init];
            dbConversationInfo.channelType = [resultSet intForColumn:@"conversation_type"];
            dbConversationInfo.channelId = [resultSet stringForColumn:@"target_id"];
            dbConversationInfo.name = [resultSet stringForColumn:@"name"];
            dbConversationInfo.avatarUrl = [resultSet stringForColumn:@"avatar_url"];
            dbConversationInfo.extra = [resultSet stringForColumn:@"extra"];
            [resultSet close];
            return dbConversationInfo;
        } else {
            [resultSet close];
            return nil;
        }
    } else {
        return nil;
    }
}

- (NSArray *)selectAllConversationInfoFromDB {
    if ([self.workingDB open]) {
        NSMutableArray *dbConversationInfoList = [[NSMutableArray alloc] init];
        NCFMResultSet *resultSet = [self.workingDB executeQuery:@"SELECT * FROM CONVERSATION_INFO"];
        while ([resultSet next]) {
            NCChannelInfo *dbConversationInfo = [[NCChannelInfo alloc] init];
            dbConversationInfo.channelType = [resultSet intForColumn:@"conversation_type"];
            dbConversationInfo.channelId = [resultSet stringForColumn:@"target_id"];
            dbConversationInfo.name = [resultSet stringForColumn:@"name"];
            dbConversationInfo.avatarUrl = [resultSet stringForColumn:@"avatar_url"];
            dbConversationInfo.extra = [resultSet stringForColumn:@"extra"];
            [dbConversationInfoList addObject:dbConversationInfo];
        }
        [resultSet close];
        return [dbConversationInfoList copy];
    } else {
        return nil;
    }
}

- (void)replaceConversationInfoFromDB:(NCChannelInfo *)conversationInfo
                          channelType:(NCChannelType)channelType
                            channelId:(NSString *)channelId {
    if ([self.workingDB open]) {
        [self.workingDB
            executeUpdate:
                @"INSERT OR REPLACE INTO CONVERSATION_INFO (conversation_type, target_id, name, "
                @"avatar_url, extra) VALUES(?, ?, ?, ?, ?)",
                @(channelType), channelId, conversationInfo.name, conversationInfo.avatarUrl,
                conversationInfo.extra];
    }
}

- (void)deleteConversationInfoFromDB:(NCChannelType)channelType channelId:(NSString *)channelId {
    if ([self.workingDB open]) {
        [self.workingDB
            executeUpdate:
                @"DELETE FROM CONVERSATION_INFO WHERE conversation_type = ? AND target_id = ?",
                @(channelType), channelId];
    }
}

- (void)deleteAllConversationInfoFromDB {
    if ([self.workingDB open]) {
        [self.workingDB executeUpdate:@"DELETE FROM CONVERSATION_INFO"];
    }
}

#pragma mark - ConversationUserInfo DB

- (NCChatUIUserInfo *)selectUserInfoFromDB:(NSString *)userId
                               channelType:(NCChannelType)channelType
                                 channelId:(NSString *)channelId {
    if ([self.workingDB open]) {
        NCFMResultSet *resultSet =
            [self.workingDB executeQuery:@"SELECT * FROM CONVERSATION_USER_INFO WHERE "
                                         @"conversation_type = ? AND target_id = ? AND user_id = ?",
                                         @(channelType), channelId, userId];
        if ([resultSet next]) {
            NCChatUIUserInfo *dbUserInfo = [[NCChatUIUserInfo alloc] init];
            dbUserInfo.userId = [resultSet stringForColumn:@"user_id"];
            dbUserInfo.name = [resultSet stringForColumn:@"name"];
            dbUserInfo.alias = [resultSet stringForColumn:@"alias"];
            dbUserInfo.avatarUrl = [resultSet stringForColumn:@"avatar_url"];
            dbUserInfo.extra = [resultSet stringForColumn:@"extra"];
            [resultSet close];
            return dbUserInfo;
        } else {
            [resultSet close];
            return nil;
        }
    } else {
        return nil;
    }
}

- (NSArray *)selectAllConversationUserInfoFromDB {
    if ([self.workingDB open]) {
        NSMutableArray *dbConversationUserInfoList = [[NSMutableArray alloc] init];
        NCFMResultSet *resultSet =
            [self.workingDB executeQuery:@"SELECT * FROM CONVERSATION_USER_INFO"];
        while ([resultSet next]) {
            NCChatUIUserInfo *dbUserInfo = [[NCChatUIUserInfo alloc] init];
            dbUserInfo.userId = [resultSet stringForColumn:@"user_id"];
            dbUserInfo.name = [resultSet stringForColumn:@"name"];
            dbUserInfo.alias = [resultSet stringForColumn:@"alias"];
            dbUserInfo.avatarUrl = [resultSet stringForColumn:@"avatar_url"];
            dbUserInfo.extra = [resultSet stringForColumn:@"extra"];
            [dbConversationUserInfoList addObject:dbUserInfo];
        }
        [resultSet close];
        return [dbConversationUserInfoList copy];
    } else {
        return nil;
    }
}

- (void)replaceUserInfoFromDB:(NCChatUIUserInfo *)userInfo
                    forUserId:(NSString *)userId
                  channelType:(NCChannelType)channelType
                    channelId:(NSString *)channelId {
    if ([self.workingDB open]) {
        [self.workingDB
            executeUpdate:
                @"INSERT OR REPLACE INTO CONVERSATION_USER_INFO (conversation_type, target_id, "
                @"user_id, name, alias, avatar_url, extra) VALUES(?, ?, ?, ?, ?, ?, ?)",
                @(channelType), channelId, userId, userInfo.name, userInfo.alias,
                userInfo.avatarUrl, userInfo.extra];
    }
}

- (void)deleteConversationUserInfoFromDB:(NSString *)userId
                             channelType:(NCChannelType)channelType
                               channelId:(NSString *)channelId {
    if ([self.workingDB open]) {
        [self.workingDB executeUpdate:@"DELETE FROM CONVERSATION_USER_INFO WHERE conversation_type "
                                      @"= ? AND target_id = ? AND user_id = ?",
                                      @(channelType), channelId, userId];
    }
}

- (void)deleteAllConversationUserInfoFromDB {
    if ([self.workingDB open]) {
        [self.workingDB executeUpdate:@"DELETE FROM CONVERSATION_USER_INFO"];
    }
}

#pragma mark - UserInfo DB

- (NCChatUIUserInfo *)selectUserInfoFromDB:(NSString *)userId {
    if ([self.workingDB open]) {
        NCFMResultSet *resultSet =
            [self.workingDB executeQuery:@"SELECT * FROM USER_INFO WHERE user_id = ?", userId];
        if ([resultSet next]) {
            NCChatUIUserInfo *dbUserInfo = [[NCChatUIUserInfo alloc] init];
            dbUserInfo.userId = [resultSet stringForColumn:@"user_id"];
            dbUserInfo.name = [resultSet stringForColumn:@"name"];
            dbUserInfo.alias = [resultSet stringForColumn:@"alias"];
            dbUserInfo.avatarUrl = [resultSet stringForColumn:@"avatar_url"];
            dbUserInfo.extra = [resultSet stringForColumn:@"extra"];
            [resultSet close];
            return dbUserInfo;
        } else {
            [resultSet close];
            return nil;
        }
    } else {
        return nil;
    }
}

- (NSArray *)selectAllUserInfoFromDB {
    if ([self.workingDB open]) {
        NSMutableArray *dbUserInfoList = [[NSMutableArray alloc] init];
        NCFMResultSet *resultSet = [self.workingDB executeQuery:@"SELECT * FROM USER_INFO"];
        while ([resultSet next]) {
            NCChatUIUserInfo *dbUserInfo = [[NCChatUIUserInfo alloc] init];
            dbUserInfo.userId = [resultSet stringForColumn:@"user_id"];
            dbUserInfo.name = [resultSet stringForColumn:@"name"];
            dbUserInfo.alias = [resultSet stringForColumn:@"alias"];
            dbUserInfo.avatarUrl = [resultSet stringForColumn:@"avatar_url"];
            dbUserInfo.extra = [resultSet stringForColumn:@"extra"];
            [dbUserInfoList addObject:dbUserInfo];
        }
        [resultSet close];
        return [dbUserInfoList copy];
    } else {
        return nil;
    }
}

- (void)replaceUserInfoFromDB:(NCChatUIUserInfo *)userInfo forUserId:(NSString *)userId {
    if ([self.workingDB open]) {
        [self.workingDB executeUpdate:@"INSERT OR REPLACE INTO USER_INFO (user_id, name, alias, "
                                      @"avatar_url, extra) VALUES(?, ?, ?, ?, ?)",
                                      userId, userInfo.name, userInfo.alias, userInfo.avatarUrl,
                                      userInfo.extra ?: @""];
    }
}

- (void)deleteUserInfoFromDB:(NSString *)userId {
    if ([self.workingDB open]) {
        [self.workingDB executeUpdate:@"DELETE FROM USER_INFO WHERE user_id = ?", userId];
    }
}

- (void)deleteAllUserInfoFromDB {
    if ([self.workingDB open]) {
        [self.workingDB executeUpdate:@"DELETE FROM USER_INFO"];
    }
}

@end
