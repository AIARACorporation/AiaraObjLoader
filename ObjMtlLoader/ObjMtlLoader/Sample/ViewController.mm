//
//  ViewController.m
//  ObjMtlLoader
//
//  Created by 맥 on 2018. 8. 8..
//  Copyright © 2018년 aiara. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)loadView
{
    [super loadView];
    glView = [GLView initialize:[[UIScreen mainScreen] bounds]];
    [glView setBackgroundColor:UIColor.clearColor];
    [glView setUserInteractionEnabled:YES];
    [self.view addSubview:glView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
