//
//  ViewController.m
//  Pie Chart Avatar
//
//  Created by Hamish Knight on 29/01/2016.
//  Copyright © 2016 Redonkulous Apps. All rights reserved.
//

#import "ViewController.h"
#import "AvatarView.h"

@implementation ViewController

-(void) viewDidLoad {
    [super viewDidLoad];
    
    AvatarView* v = [[AvatarView alloc] initWithFrame:CGRectMake(50, 50, 200, 200)];
    v.avatarImage = [UIImage imageNamed:@"photo.png"];
    v.borderWidth = 10;
    v.borderColors = @[[UIColor colorWithRed:122.0/255.0 green:108.0/255.0 blue:255.0/255.0 alpha:1],
                       [UIColor colorWithRed:100.0/255.0 green:241.0/255.0 blue:183.0/255.0 alpha:1],
                       [UIColor colorWithRed:0 green:222.0/255.0 blue:255.0/255.0 alpha:1]];
    v.borderValues = @[@(0.4), @(0.35), @(0.25)];
    
    
    
    [self.view addSubview:v];
    
}

@end
