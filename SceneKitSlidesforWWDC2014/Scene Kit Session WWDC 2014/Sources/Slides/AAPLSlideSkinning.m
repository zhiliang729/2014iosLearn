/*
 <codex>
 <abstract>Illustates how skinning can be used to animate characters.</abstract>
 </codex>
 */

#import "AAPLPresentationViewController.h"
#import "AAPLSlideTextManager.h"
#import "AAPLSlide.h"
#import "Utils.h"

@interface AAPLSlideSkinning : AAPLSlide
@end

@implementation AAPLSlideSkinning {
    CAAnimationGroup *_idleAnimationGroup;
    CAAnimationGroup *_animationGroup1;
    CAAnimationGroup *_animationGroup2;
    
    SCNNode *_characterNode;
    SCNNode *_skeletonNode;
}

- (void)setupSlideWithPresentationViewController:(AAPLPresentationViewController *)presentationViewController
{
    // Using a scene source allows us to retrieve the animations using their identifier
    NSURL *sceneURL = [[NSBundle mainBundle] URLForResource:@"skinning" withExtension:@"dae" subdirectory:@"Scenes.scnassets/skinning"];
    SCNSceneSource *sceneSource = [SCNSceneSource sceneSourceWithURL:sceneURL options:nil];
    
    // Place the character in the scene
    SCNScene *scene = [sceneSource sceneWithOptions:nil error:nil];
    _characterNode = [scene.rootNode childNodeWithName:@"avatar_attach" recursively:YES];
    _characterNode.scale = SCNVector3Make(0.004, 0.004, 0.004);
    _characterNode.position = SCNVector3Make(5, 0, 12);
    _characterNode.rotation = SCNVector4Make(0, 1, 0, -M_PI / 8);
    _characterNode.hidden = YES;
    [self.groundNode addChildNode:_characterNode];
    
    _skeletonNode = [_characterNode childNodeWithName:@"skeleton" recursively:YES];
    
    // Prepare the other resources
    [self loadGhostEffect];
    [self extractAnimationsFromSceneSource:sceneSource];
}

- (NSUInteger)numberOfSteps
{
    return 7;
}

- (void)presentStepIndex:(NSUInteger)index withPresentationViewController:(AAPLPresentationViewController *)presentationViewController
{
    [SCNTransaction begin];
    
    switch (index) {
        case 0:
        {
            // Set the slide's title and subtitle and add some text
            self.textManager.title = @"Skinning";
            
            [self.textManager addBullet:@"Animate characters" atLevel:0];
            [self.textManager addBullet:@"Deform geometries with a skeleton" atLevel:0];
            [self.textManager addBullet:@"Joints and bones" atLevel:0];
            
            // Animate the character
            [_characterNode addAnimation:_idleAnimationGroup forKey:@"idleAnimation"];
            
            // The character is hidden. Wait a little longer before showing it
            // otherwise it may slow down the transition from the previous slide
            double delayInSeconds = 1.5;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                [SCNTransaction begin];
                [SCNTransaction setAnimationDuration:0];
                {
                    _characterNode.hidden = NO;
                    _characterNode.opacity = 0;
                }
                [SCNTransaction commit];
                
                [SCNTransaction begin];
                [SCNTransaction setAnimationDuration:1.5];
                [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
                {
                    _characterNode.opacity = 1;
                }
                [SCNTransaction commit];
            });
            break;
        }
        case 1:
            [SCNTransaction setAnimationDuration:1.5];
            [self setShowsBones:YES];
            break;
        case 2:
            [_characterNode addAnimation:_animationGroup1 forKey:@"animation"];
            break;
        case 3:
            [SCNTransaction setAnimationDuration:1.5];
            [self setShowsBones:NO];
            break;
        case 4:
            [_characterNode addAnimation:_animationGroup1 forKey:@"animation"];
            break;
        case 5:
            // Simulate a new slide by changing all the text and animate these changes
            [self.textManager flipOutTextOfType:AAPLTextTypeBullet];
            
            self.textManager.subtitle = @"SCNSkinner";
            
            [self.textManager addBullet:@"Can be loaded from DAEs" atLevel:0];
            [self.textManager addBullet:@"Can be created programmatically" atLevel:0];
            
            [self.textManager flipInTextOfType:AAPLTextTypeBullet];
            [self.textManager flipInTextOfType:AAPLTextTypeSubtitle];
            break;
        case 6:
            [_characterNode addAnimation:_animationGroup2 forKey:@"animation"];
            break;
    }
    
    [SCNTransaction commit];
}


#pragma mark - Animations

- (void)extractAnimationsFromSceneSource:(SCNSceneSource *)sceneSource
{
    // In this scene objects are animated separately using long animations
    // playing 3 successive animations. We will group these long animations
    // and then split the group in 3 different animation groups.
    // We could also have used three DAEs (one per animation).
    
    NSArray *animationIDs = [sceneSource identifiersOfEntriesWithClass:[CAAnimation class]];
    
    NSUInteger animationCount = [animationIDs count];
    NSMutableArray *longAnimations = [[NSMutableArray alloc] initWithCapacity:animationCount];
    
    CFTimeInterval maxDuration = 0;
    
    for (NSInteger index = 0; index < animationCount; index++) {
        CAAnimation *animation = [sceneSource entryWithIdentifier:animationIDs[index] withClass:[CAAnimation class]];
        if (animation) {
            maxDuration = MAX(maxDuration, animation.duration);
            [longAnimations addObject:animation];
        }
    }
    
    CAAnimationGroup *longAnimationsGroup = [[CAAnimationGroup alloc] init];
    longAnimationsGroup.animations = longAnimations;
    longAnimationsGroup.duration = maxDuration;
    
    CAAnimationGroup *idleAnimationGroup = [longAnimationsGroup copy];
    idleAnimationGroup.timeOffset = 6.45833333333333;
    _idleAnimationGroup = [CAAnimationGroup animation];
    _idleAnimationGroup.animations = @[idleAnimationGroup];
    _idleAnimationGroup.duration = 24.71 - 6.45833333333333;
    _idleAnimationGroup.repeatCount = FLT_MAX;
    _idleAnimationGroup.autoreverses = YES;
    
    CAAnimationGroup *animationGroup1 = [longAnimationsGroup copy];
    _animationGroup1 = [CAAnimationGroup animation];
    _animationGroup1.animations = @[animationGroup1];
    _animationGroup1.duration = 1.4;
    _animationGroup1.fadeInDuration = 0.1;
    _animationGroup1.fadeOutDuration = 0.5;
    
    CAAnimationGroup *animationGroup2 = [longAnimationsGroup copy];
    animationGroup2.timeOffset = 3.666666666666667;
    _animationGroup2 = [CAAnimationGroup animation];
    _animationGroup2.animations = @[animationGroup2];
    _animationGroup2.duration = 6.416666666666667 - 3.666666666666667;
    _animationGroup2.fadeInDuration = 0.1;
    _animationGroup2.fadeOutDuration = 0.5;
}


#pragma mark - Ghost effect

- (void)loadGhostEffect
{
    NSURL *shaderURL = [[NSBundle mainBundle] URLForResource:@"character" withExtension:@"shader"];
    NSString *fragmentModifier = [NSString stringWithContentsOfURL:shaderURL encoding:NSUTF8StringEncoding error:nil];
    
    NSDictionary *modifiers = @{ SCNShaderModifierEntryPointFragment : fragmentModifier };
    [self setShaderModifiers:modifiers onNode:_characterNode];
}

- (void)applyGhostEffect:(BOOL)show onNode:(SCNNode *)node
{
    // Uniforms in your GLSL shaders can be set using KVC
    // The following line will set the 'ghostFactor' uniform found in the 'character.shader' file
    [node.geometry setValue:@(show) forKey:@"ghostFactor"];
    
    for (SCNNode *child in node.childNodes)
        [self applyGhostEffect:show onNode:child];
}

- (void)setShaderModifiers:(NSDictionary *)modifiers onNode:(SCNNode *)node
{
    node.geometry.shaderModifiers = modifiers;
    
    for (SCNNode *childNode in node.childNodes)
        [self setShaderModifiers:modifiers onNode:childNode];
}


#pragma mark - Skeleton visualisation

- (void)setShowsBones:(BOOL)show
{
    [self visualizeBones:show ofNode:_skeletonNode inheritedScale:1];
    [self applyGhostEffect:show onNode:_characterNode];
}

- (void)visualizeBones:(BOOL)show ofNode:(SCNNode *)node inheritedScale:(CGFloat)scale
{
    // We propagate an inherited scale so that the boxes
    // representing the bones will be of the same size
    scale *= node.scale.x;
    
    if (show) {
        if (node.geometry == nil)
            node.geometry = [SCNBox boxWithWidth:6.0 / scale height:6.0 / scale length:6.0 / scale chamferRadius:0.5];
    }
    else {
        if ([node.geometry isKindOfClass:[SCNBox class]])
            node.geometry = nil;
    }
    
    for (SCNNode *child in node.childNodes)
        [self visualizeBones:show ofNode:child inheritedScale:scale];
}

@end