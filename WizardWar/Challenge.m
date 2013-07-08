//
//  Invite.m
//  WizardWar
//
//  Created by Sean Hess on 5/17/13.
//  Copyright (c) 2013 The LAB. All rights reserved.
//

#import "Challenge.h"
#import "NSArray+Functional.h"

@implementation Challenge

-(NSDictionary*)toObject {
    return @{@"mainId": self.main.userId, @"opponentId": self.opponent.userId};
//    return [self dictionaryWithValuesForKeys:@[@"mainId", @"opponentId"]];
}

-(void)setValuesForKeysWithDictionary:(NSDictionary *)values {
    [super setValuesForKeysWithDictionary:values];
    
//    self.main = [User new];
//    self.main.userId = values[@"mainId"];
//    self.opponent = [User new];
//    self.opponent.userId = values[@"opponentId"];
}

-(NSString*)matchId {
    NSArray * ids = [@[self.main, self.opponent] map:^(User*user) {
        return user.userId;
    }];
    NSArray * sorted = [ids sortedArrayUsingSelector:@selector(compare:)];
    return [NSString stringWithFormat:@"%@_vs_%@", sorted[0], sorted[1]];
}

@end
