//
//  GLView.m
//  ObjMtlLoader
//
//  Created by 맥 on 2018. 8. 8..
//  Copyright © 2018년 aiara. All rights reserved.
//

#import "GLView.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>

@interface GLView ()

- (void) initializeDefaults;
- (void) initializeShaders;
- (void) initializeResources;

- (void) createFramebuffer;
- (void) deleteFramebuffer;
- (void) setFramebuffer;
- (void) presentFramebuffer;

@end

@implementation GLView

+ (Class)layerClass { return [CAEAGLLayer class]; }

+ (id) initialize:(CGRect)frame
{
    return [[GLView alloc] initWithFrame:frame];
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initializeDefaults];
        [self initializeShaders];
        [self initializeResources];
        
        CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    return self;
}

- (void) initializeDefaults
{
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (context != [EAGLContext currentContext])
        [EAGLContext setCurrentContext:context];
    
    projectionMat = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), std::abs(self.bounds.size.width / self.bounds.size.height), 0.01f, 5000.0f);
    viewMat = GLKMatrix4MakeLookAt(0.0f, 2.5f, 2.0f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f);
}
- (void) initializeShaders
{
    shader = [Shader alloc];
    [shader initialize];
}
- (void) initializeResources
{
    model = [Model3D initialize:@"sample.obj" andMaterial:[self getFilePath:@"sample.mtl"] andTextures:[NSArray arrayWithObjects:[self getFilePath:@"sample.jpg"], nil]];
    modelMat = GLKMatrix4Make(1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f);
}

- (NSString*) getFilePath:(NSString*)filename
{
    NSString *extension = [filename pathExtension];
    NSString *fileName = [filename stringByDeletingPathExtension];
    return [[NSBundle mainBundle] pathForResource:fileName ofType:extension];
}

- (void) createFramebuffer
{
    if (context)
    {
        // Create default framebuffer object
        glGenFramebuffers(1, &frameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
        
        // Create colour renderbuffer and allocate backing store
        glGenRenderbuffers(1, &colorBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorBuffer);
        
        // Allocate the renderbuffer's storage (shared with the drawable object)
        [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        GLint framebufferWidth;
        GLint framebufferHeight;
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
        
        // Create the depth render buffer and allocate storage
        glGenRenderbuffers(1, &depthBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthBuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, framebufferWidth, framebufferHeight);
        
        // Attach colour and depth render buffers to the frame buffer
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorBuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthBuffer);
        
        // Leave the colour render buffer bound so future rendering operations will act on it
        glBindRenderbuffer(GL_RENDERBUFFER, colorBuffer);
        glViewport(0, 0, self.bounds.size.width,self.bounds.size.height);
    }
}
- (void) deleteFramebuffer
{
    if (context)
    {
        [EAGLContext setCurrentContext:context];
        if (frameBuffer)
        {
            glDeleteFramebuffers(1, &frameBuffer);
            frameBuffer = 0;
        }
        if (colorBuffer)
        {
            glDeleteFramebuffers(1, &colorBuffer);
            colorBuffer = 0;
        }
        if (depthBuffer)
        {
            glDeleteFramebuffers(1, &depthBuffer);
            depthBuffer = 0;
        }
    }
}
- (void) setFramebuffer
{
    if (context != [EAGLContext currentContext])
        [EAGLContext setCurrentContext:context];
    if (!frameBuffer)
        [self performSelectorOnMainThread:@selector(createFramebuffer) withObject:self waitUntilDone:YES];
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glClearColor(1.0f, 0.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}
- (void) presentFramebuffer
{
    glBindRenderbuffer(GL_RENDERBUFFER, colorBuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void) dealloc
{
    [self deleteFramebuffer];
    [EAGLContext setCurrentContext:nil];
    context = nil;
}

- (void) render:(CADisplayLink *)displayLink
{
    [self setFramebuffer];
    modelMat = GLKMatrix4Rotate(modelMat, GLKMathDegreesToRadians(2.0f), 0.0f, 1.0f, 0.0f);
    [self renderModel:model andMatrix:modelMat];
    [self presentFramebuffer];
}

- (void) renderModel:(Model3D*)useModel andMatrix:(GLKMatrix4&)modelPoseMat
{
    GLKMatrix4 mvMat = GLKMatrix4Multiply(viewMat, modelPoseMat);
    GLKMatrix4 mvpMat = GLKMatrix4Multiply(projectionMat, mvMat);
    
    glUseProgram(shader.shaderProgramID);
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBlendEquation(GL_FUNC_ADD);
    
    glEnable(GL_BLEND);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    
    glVertexAttribPointer(shader.vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)[useModel getVertices]);
    glVertexAttribPointer(shader.normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)[useModel getNormals]);
    glVertexAttribPointer(shader.textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)[useModel getTexCoords]);
    
    glEnableVertexAttribArray(shader.vertexHandle);
    glEnableVertexAttribArray(shader.normalHandle);
    glEnableVertexAttribArray(shader.textureCoordHandle);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, [useModel getTextureID:0]);
    
    glUniformMatrix4fv(shader.mvpMatrixHandle, 1, GL_FALSE, (const GLfloat*)mvpMat.m);
    glUniformMatrix4fv(shader.mvMatrixHandle, 1, GL_FALSE, (const GLfloat*)mvMat.m);
    
    glUniform4f(shader.materialHandle, [useModel getAmbient], [useModel getDiffuse], [useModel getSpecular], [useModel getSpecularPower]);
    glUniform4f(shader.lightingHandle, 0, 0, 1.0f, 1.0f);
    glUniform1f(shader.transparencyHandle, 1.0f);
    glUniform1i(shader.texSampler2DHandle, 0);
    glDrawElements(GL_TRIANGLES, [useModel getElementCount], [useModel getElementType], [useModel getElements]);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    glDisableVertexAttribArray(shader.vertexHandle);
    glDisableVertexAttribArray(shader.normalHandle);
    glDisableVertexAttribArray(shader.textureCoordHandle);
    
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_BLEND);
}

@end
