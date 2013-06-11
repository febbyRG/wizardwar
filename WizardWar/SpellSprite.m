//
//  SpellSprite.m
//  WizardWar
//
//  Created by Sean Hess on 5/17/13.
//  Copyright (c) 2013 The LAB. All rights reserved.
//

#import "SpellSprite.h"
#import "cocos2d.h"
#import "SpellFireball.h"
#import "SpellEarthwall.h"
#import "SpellVine.h"
#import "SpellMonster.h"
#import "SpellBubble.h"
#import "SpellIcewall.h"
#import "SpellWindblast.h"
#import "SpellInvisibility.h"
#import <ReactiveCocoa.h>

@interface SpellSprite ()
@property (nonatomic, strong) Units * units;
@property (nonatomic, strong) CCSprite * skin;
@property (nonatomic, strong) CCSpriteBatchNode * sheet;
@property (nonatomic, strong) CCAction * action;
@property (nonatomic, strong) CCSpriteBatchNode * explosion;
@end

@implementation SpellSprite

+(void)loadSprites {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"LOAD SPELL SPRITES");
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"explode.plist"];
        [[CCAnimationCache sharedAnimationCache] addAnimationsWithFile:@"explode-animation.plist"];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"fireball.plist"];
        [[CCAnimationCache sharedAnimationCache] addAnimationsWithFile:@"fireball-animation.plist"];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"earthwall.plist"];
        [[CCAnimationCache sharedAnimationCache] addAnimationsWithFile:@"earthwall-animation.plist"];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"vine.plist"];
        [[CCAnimationCache sharedAnimationCache] addAnimationsWithFile:@"vine-animation.plist"];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"ogre.plist"];
        [[CCAnimationCache sharedAnimationCache] addAnimationsWithFile:@"ogre-animation.plist"];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"bubble.plist"];
        [[CCAnimationCache sharedAnimationCache] addAnimationsWithFile:@"bubble-animation.plist"];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"icewall.plist"];
        [[CCAnimationCache sharedAnimationCache] addAnimationsWithFile:@"icewall-animation.plist"];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"windblast.plist"];
        [[CCAnimationCache sharedAnimationCache] addAnimationsWithFile:@"windblast-animation.plist"];        
    });
}


-(id)initWithSpell:(Spell*)spell units:(Units *)units {
    if ((self=[super init])) {
        self.spell = spell;
        self.units = units;
        
        if ([spell isType:[SpellInvisibility class]]) {
            return self;
        }
        
        [SpellSprite loadSprites];
        
        self.sheet = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"%@.png", self.sheetName]];
        [self addChild:self.sheet];
        
        self.skin = [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"%@-1.png", self.sheetName]];
        [self.skin runAction:self.spellAction];
        [self.sheet addChild:self.skin];
        
        
        [[RACAble(self.spell.position) distinctUntilChanged] subscribeNext:^(id x) {
            [self renderPosition];
        }];
        
        [[RACAble(self.spell.strength) distinctUntilChanged] subscribeNext:^(id x) {
            [self renderWallStrength];
        }];
        
        
        [[RACAble(self.spell.status) distinctUntilChanged] subscribeNext:^(id x) {
            [self renderStatus];
        }];
        
        [[RACAble(self.spell.direction) distinctUntilChanged] subscribeNext:^(id x) {
            [self renderDirection];
        }];
        
        
        [self renderPosition];
        [self renderWallStrength];
        [self renderDirection];
        [self renderStatus];
    }
    return self;
}

-(BOOL)isWall:(Spell*)spell {
    return ([self.spell isType:[SpellEarthwall class]] || [self.spell isType:[SpellIcewall class]]);
}

-(void)renderDirection {
    self.skin.flipX = (self.spell.direction < 0);
}

-(void)renderPosition {
    CGFloat y = self.units.zeroY;
    if ([self isWall:self.spell]) {
        // bump walls down
        y -= 25;
    }
    
    self.position = ccp([self.units toX:self.spell.position], y);
}

- (void)renderWallStrength {
    if (![self isWall:self.spell]) return;
    NSString * frameName = [NSString stringWithFormat:@"%@-%i.png", self.sheetName, (self.spell.strength+1)];
    [self.skin setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:frameName]];
}

- (void)renderStatus {
    self.skin.visible = (self.spell.status == SpellStatusActive || self.spell.status == SpellStatusPrepare);
//    NSLog(@" - status=%i", self.spell.status);
    
    if (!self.explosion && self.spell.status == SpellStatusDestroyed) {
        self.explosion = [CCSpriteBatchNode batchNodeWithFile:@"explode.png"];
        [self addChild:self.explosion];
        CCSprite * sprite = [CCSprite spriteWithSpriteFrameName:@"explode-1"];
        [sprite runAction:self.explodeAction];
        [self.explosion addChild:sprite];
    }
}

-(NSString*)sheetName {
    if ([self.spell isType:[SpellEarthwall class]]) {
        return @"earthwall";
    }
    
    else if ([self.spell isType:[SpellVine class]]) {
        return @"vine";
    }
    
    else if ([self.spell isType:[SpellMonster class]]) {
        return @"ogre";
    }
    
    else if ([self.spell isType:[SpellBubble class]]) {
        return @"bubble";
    }
    
    else if ([self.spell isType:[SpellIcewall class]]) {
        return @"icewall";
    }
    
    else if ([self.spell isType:[SpellWindblast class]]) {
        return @"windblast";
    }
    
    return @"fireball";
}

-(CCAction*)spellAction {
    CCAnimation *animation = [[CCAnimationCache sharedAnimationCache] animationByName:self.castAnimationName];
    animation.restoreOriginalFrame = NO;
    
    CCActionInterval * actionInterval = [CCAnimate actionWithAnimation:animation];
    CCAction * action = actionInterval;
    
    if ([self.spell isType:[SpellFireball class]] || [self.spell isType:[SpellBubble class]] || [self.spell isType:[SpellWindblast class]] || [self.spell isType:[SpellMonster class]]) {
        action = [CCRepeatForever actionWithAction:actionInterval];
    }
    
    return action;
}

-(NSString*)castAnimationName {
    return [NSString stringWithFormat:@"%@-cast", self.sheetName];
}

-(CCAction*)explodeAction {
    CCAnimation *animation = [[CCAnimationCache sharedAnimationCache] animationByName:@"explode"];
    animation.restoreOriginalFrame = NO;
    CCActionInterval * actionInterval = [CCAnimate actionWithAnimation:animation];
    return actionInterval;
}

@end
