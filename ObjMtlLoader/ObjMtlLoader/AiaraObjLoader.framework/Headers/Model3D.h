//
//  Model3D.h
//  ModelViewer
//
//  Created by MJ on 07.16.18.
//  Copyright © 2017 3d4medical. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>
#include <vector>

#import "Texture2D.h"

@interface Model3D : NSObject
{
@private
    GLfloat* vertices;
    GLfloat* texCoords;
    GLfloat* normals;
    void* elements;
    bool isLoaded;
    
    GLuint componentCount;
    GLuint vertexCount;
    GLuint elementCount;
    GLuint elementSize;
    GLenum elementType;
    
    float diffuse;
    float ambient;
    float specular;
    float specularPower;
    
    NSString* objName;
    std::vector<Texture2D*> textures;
}

+ (id) initialize:(NSString*)objPath andMaterial:(NSString*)materialPath andTextures:(NSArray*)texturesArray;

- (GLfloat*) getVertices;
- (GLfloat*) getTexCoords;
- (GLfloat*) getNormals;
- (void*) getElements;

- (GLuint) getComponentCount;
- (GLuint) getVertexCount;
- (GLuint) getElementCount;
- (GLuint) getElementSize;
- (GLuint) getElementType;

- (float) getDiffuse;
- (float) getAmbient;
- (float) getSpecular;
- (float) getSpecularPower;

- (int) getTextureID:(int)num;

@end
