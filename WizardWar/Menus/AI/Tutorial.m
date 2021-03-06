//
//  AITutorial1BasicMagic.m
//  WizardWar
//
//  Created by Sean Hess on 8/24/13.
//  Copyright (c) 2013 Orbital Labs. All rights reserved.
//

#import "Tutorial.h"
#import "UIColor+Hex.h"
#import <ReactiveCocoa.h>
#import "Spell.h"
#import "EnvironmentLayer.h"
#import "RACSignal+Filters.h"
#import "Combo.h"
#import "SpellEffectService.h"
#import "Wizard.h"

@interface Tutorial ()
@property (nonatomic, strong) TutorialStep * currentStep;
@property (nonatomic) NSInteger wizardHealth;
@property (nonatomic) NSInteger opponentHealth;
@end

@implementation Tutorial

// Advance Conditions
// 1. cast a certain spell

-(id)init {
    if ((self = [super init])) {
        Wizard * wizard = [Wizard new];
        wizard.name = @"Horzo the Helpful";
        wizard.wizardType = WIZARD_TYPE_ONE;
        wizard.color = [UIColor colorFromRGB:0x005EA8];
        self.wizard = wizard;
        self.hideControls = YES;
        self.disableControls = YES;
        self.environment = ENVIRONMENT_CASTLE;        
    }
    return self;
}

-(void)setSteps:(NSArray *)steps {
    _steps = steps;
    [self loadStep:0];
}

-(BOOL)didLoseGame {
    return (self.wizard.health == 0);
}

-(void)loadStep:(NSInteger)stepIndex {
    self.currentStepIndex = stepIndex;
    if (stepIndex >= self.steps.count) return;
    TutorialStep * currentStep = self.steps[stepIndex];
    self.currentStep = currentStep;
    NSLog(@"TUTORIAL STEP: %@", currentStep);
    
    self.disableControls = currentStep.disableControls;
    self.hideControls = currentStep.hideControls;
    self.allowedSpells = currentStep.allowedSpells;
    self.tactics = currentStep.tactics;
    
    if (currentStep.loseMessage && self.didLoseGame)
        self.wizard.message = currentStep.loseMessage;
    else
        self.wizard.message = currentStep.message;
    
    if (currentStep.demoSpellType) {
        SpellInfo * demoInfo = [SpellEffectService.shared infoForType:currentStep.demoSpellType];
        self.helpSelectedElements = demoInfo.combo.selectedElements.elements;
    } else {
        self.helpSelectedElements = nil;
    }
//    self.wizard.health = MAX_HEALTH;
}

-(void)opponent:(Wizard*)wizard didCastSpell:(Spell*)spell atTick:(NSInteger)tick {
    [super opponent:wizard didCastSpell:spell atTick:tick];
    
    if (self.currentStep.advanceOnAnySpell || (self.currentStep.advanceOnSpell && [spell isType:self.currentStep.advanceOnSpell])) {
        [self advance];
    }
}

-(void)setWizardHealth:(NSInteger)health {
    BOOL shouldAdvance = ((self.currentStep.advanceOnDamage && health < _wizardHealth) || (self.currentStep.advanceOnEnd && health == 0));
    _wizardHealth = health;
    if (shouldAdvance) [self advance];
}

-(void)setOpponentHealth:(NSInteger)health {
    BOOL shouldAdvance = ((self.currentStep.advanceOnDamageOpponent && health < _opponentHealth) || (self.currentStep.advanceOnEnd && health == 0));
    _opponentHealth = health;
    if (shouldAdvance) [self advance];
}

-(void)advance {
    [self loadStep:self.currentStepIndex+1];
}

-(void)didTapControls {
    if (self.currentStep.advanceOnTap) {
        [self advance];
    }
}

@end
