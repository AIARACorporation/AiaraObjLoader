//
//  GLView.h
//  ObjMtlLoader
//
//  Created by 맥 on 2018. 8. 8..
//  Copyright © 2018년 aiara. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Shader.h"
#import <AiaraObjLoader/AiaraObjLoader.h>

@interface GLView : UIView
{
    EAGLContext *context;
    CAEAGLLayer *eaglLayer;
    
    GLuint frameBuffer;
    GLuint colorBuffer;
    GLuint depthBuffer;
    
    Shader* shader;
    Model3D* model;
    
    GLKMatrix4 projectionMat;
    GLKMatrix4 viewMat;
    GLKMatrix4 modelMat;
}

+ (id) initialize:(CGRect)frame;

@end
