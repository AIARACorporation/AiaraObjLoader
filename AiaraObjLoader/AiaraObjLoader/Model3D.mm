//
//  Model3D.mm
//  ModelViewer
//
//  Created by MJ on 07.16.18.
//  Copyright © 2018 3d4medical. All rights reserved.
//

#import "Model3D.h"

#pragma clang diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
#pragma clang diagnostic ignored "-Wpointer-arith"
#pragma clang diagnostic ignored "-Wconversion"
#pragma clang diagnostic ignored "-Wgnu"

typedef struct
{
    char fileIdentifier[32];
    unsigned int majorVersion;
    unsigned int minorVersion;
}
WWDC2010Header;


typedef struct
{
    unsigned int attribHeaderSize;
    unsigned int byteElementOffset;
    unsigned int bytePositionOffset;
    unsigned int byteTexcoordOffset;
    unsigned int byteNormalOffset;
}
WWDC2010TOC;


typedef struct
{
    unsigned int byteSize;
    GLenum datatype;
    GLenum primType;
    unsigned int sizePerElement;
    unsigned int numElements;
}
WWDC2010Attributes;


@interface NSString (Private)

- (NSString *)GL_normalizedPathWithDefaultExtension:(NSString *)extension;

@end


@interface NSData (Private)

- (NSData *)GL_unzippedData;

@end

@implementation Model3D

+ (id) initialize:(NSString*)objPath andMaterial:(NSString*)materialPath andTextures:(NSArray*)texturesArray
{
    Model3D* model = [Model3D alloc];
    [model initialize:objPath andMaterial:materialPath andTextures:texturesArray];
    return model;
}

- (void) initialize:(NSString*)objPath andMaterial:(NSString*)materialPath andTextures:(NSArray*)texturesArray
{
    isLoaded = false;
    objName = objPath;
    
    NSString *path = [objPath GL_normalizedPathWithDefaultExtension:@"obj"];
    if (![self initWithData:[NSData dataWithContentsOfFile:path]])
        return;
    [self initMaterial:materialPath];
    
    int nCnt = (int)[texturesArray count];
    for (int i = 0; i < nCnt; i++)
        textures.push_back([Texture2D initializeWithPath:[texturesArray objectAtIndex:i]]);
    isLoaded = true;
}

- (bool) initWithData:(NSData *)data
{
    data = [data GL_unzippedData];
    if (!data)
        return false;
    if ([self loadAppleWWDC2010Model:data] || [self loadObjModel:data])
        return true;
    return false;
}

- (void) initMaterial:(NSString *)path
{
    diffuse = 0.8f;
    ambient = 0.2f;
    specular = 0.0f;
    specularPower = 65.0f;
    
    NSString *mtlData = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSArray *mtlLines = [mtlData componentsSeparatedByString:@"\n"];
    
    // Can't use fast enumeration here, need to manipulate line order
    for (int i = 0; i < [mtlLines count]; i++)
    {
        NSString *line = [mtlLines objectAtIndex:i];
        if ([line hasPrefix:@"newmtl"]) // Start of new material
        {
            // Determine start of next material
            int mtlEnd = -1;
            for (int j = i+1; j < [mtlLines count]; j++)
            {
                NSString *innerLine = [mtlLines objectAtIndex:j];
                if ([innerLine hasPrefix:@"newmtl"])
                {
                    mtlEnd = j-1;
                    break;
                }
            }
            if (mtlEnd == -1)
                mtlEnd = [mtlLines count]-1;
            for (int j = i; j <= mtlEnd; j++)
            {
                NSString *parseLine = [mtlLines objectAtIndex:j];
                // ignore Ni, d, and illum, and texture - at least for now
                if ([parseLine hasPrefix:@"newmtl "])
                {
                }
                else if ([parseLine hasPrefix:@"Ns "])
                    specularPower = [[parseLine substringFromIndex:3] floatValue];
                else if ([parseLine hasPrefix:@"Ka spectral"]) // Ignore, don't want consumed by next else
                {
                }
                else if ([parseLine hasPrefix:@"Ka "])  // CIEXYZ currently not supported, must be specified as RGB
                {
                    NSArray *colorParts = [[parseLine substringFromIndex:3] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    ambient = [[colorParts objectAtIndex:0] floatValue];
                }
                else if ([parseLine hasPrefix:@"Kd "])
                {
                    NSArray *colorParts = [[parseLine substringFromIndex:3] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    diffuse = [[colorParts objectAtIndex:0] floatValue];
                }
                else if ([parseLine hasPrefix:@"Ks "])
                {
                    NSArray *colorParts = [[parseLine substringFromIndex:3] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    specular = [[colorParts objectAtIndex:0] floatValue];
                }
                else if ([parseLine hasPrefix:@"map_Kd "])
                {
                }
            }
            i = mtlEnd;
        }
    }
}

- (bool)loadAppleWWDC2010Model:(NSData *)data
{
    if ([data length] < sizeof(WWDC2010Header) + sizeof(WWDC2010TOC))
    {
        //can't be correct file type
        return false;
    }
    
    //check header
    const WWDC2010Header *header = (const WWDC2010Header *)[data bytes];
    if(strncmp(header->fileIdentifier, "AppleOpenGLDemoModelWWDC2010", sizeof(header->fileIdentifier)))
    {
        return false;
    }
    if(header->majorVersion != 0 && header->minorVersion != 1)
    {
        return false;
    }
    
    //load table of contents
    WWDC2010TOC *toc = (WWDC2010TOC *)([data bytes]);
    toc = toc + sizeof(WWDC2010Header);
    if(toc->attribHeaderSize > sizeof(WWDC2010Attributes))
    {
        return false;
    }
    
    //copy elements
    WWDC2010Attributes *elementAttributes = (WWDC2010Attributes *)([data bytes]);
    elementAttributes = elementAttributes + toc->byteElementOffset;
    if (elementAttributes->primType != GL_TRIANGLES)
    {
        //TODO: extend GLModel with support for other primitive types
        return false;
    }
    elementSize = elementAttributes->byteSize / elementAttributes->numElements;
    switch (elementSize) {
        case sizeof(GLuint):
            elementType = GL_UNSIGNED_INT;
            break;
        case sizeof(GLushort):
            elementType = GL_UNSIGNED_SHORT;
            break;
        case sizeof(GLubyte):
            elementType = GL_UNSIGNED_BYTE;
            break;
    }
    elementCount = elementAttributes->numElements;
    elements = malloc(elementAttributes->byteSize);
    memcpy(elements, elementAttributes + 1, elementAttributes->byteSize);
    
    //copy vertex data
    WWDC2010Attributes *vertexAttributes = (WWDC2010Attributes *)([data bytes]);
    vertexAttributes = vertexAttributes + toc->bytePositionOffset;
    if (vertexAttributes->datatype != GL_FLOAT)
    {
        //TODO: extend GLModel with support for other data types
        return false;
    }
    componentCount = 4;
    vertexCount = vertexAttributes->numElements;
    vertices = (GLfloat*)malloc(vertexAttributes->byteSize);
    memcpy(vertices, vertexAttributes + 1, vertexAttributes->byteSize);
    
    //copy text coord data
    WWDC2010Attributes *texCoordAttributes = (WWDC2010Attributes *)([data bytes]);
    texCoordAttributes = texCoordAttributes + toc->byteTexcoordOffset;
    if (texCoordAttributes->datatype != GL_FLOAT)
    {
        //TODO: extend GLModel with support for other data types
        return false;
    }
    if (texCoordAttributes->byteSize)
    {
        texCoords = (GLfloat*)malloc(texCoordAttributes->byteSize);
        memcpy(texCoords, texCoordAttributes + 1, texCoordAttributes->byteSize);
    }
    
    //copy normal data
    WWDC2010Attributes *normalAttributes = (WWDC2010Attributes *)([data bytes]);
    normalAttributes = normalAttributes + toc->byteNormalOffset;
    if (normalAttributes->datatype != GL_FLOAT)
    {
        //TODO: extend GLModel with support for other data types
        return false;
    }
    if (normalAttributes->byteSize)
    {
        normals = (GLfloat*)malloc(normalAttributes->byteSize);
        memcpy(normals, normalAttributes + 1, normalAttributes->byteSize);
    }
    
    //success
    return true;
}

- (bool) loadObjModel:(NSData *)data
{
    char* tempPointer = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types-discards-qualifiers"
    //convert to string
    tempPointer = reinterpret_cast<char*>(const_cast<void*>(data.bytes));
    NSString *string = [[NSString alloc] initWithBytesNoCopy:(void*)tempPointer length:data.length encoding:NSASCIIStringEncoding freeWhenDone:NO];
#pragma clang diagnostic pop
    
    //set up storage
    NSMutableData *tempVertexData = [[NSMutableData alloc] init];
    NSMutableData *vertexData = [[NSMutableData alloc] init];
    NSMutableData *tempTextCoordData = [[NSMutableData alloc] init];
    NSMutableData *textCoordData = [[NSMutableData alloc] init];
    NSMutableData *tempNormalData = [[NSMutableData alloc] init];
    NSMutableData *normalData = [[NSMutableData alloc] init];
    NSMutableData *faceIndexData = [[NSMutableData alloc] init];
    
    //utility collections
    NSInteger uniqueIndexStrings = 0;
    NSMutableDictionary *indexStrings = [[NSMutableDictionary alloc] init];
    
    //scan through lines
    NSString *line = nil;
    NSScanner *lineScanner = [NSScanner scannerWithString:string];
    do
    {
        //get line
        [lineScanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&line];
        NSScanner *scanner = [NSScanner scannerWithString:line];
        
        //get line type
        NSString *type = nil;
        [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&type];
        
        if ([type isEqualToString:@"v"])
        {
            //vertex
            GLfloat coords[3];
            [scanner scanFloat:&coords[0]];
            [scanner scanFloat:&coords[1]];
            [scanner scanFloat:&coords[2]];
            [tempVertexData appendBytes:coords length:sizeof(coords)];
        }
        else if ([type isEqualToString:@"vt"])
        {
            //texture coordinate
            GLfloat coords[2];
            [scanner scanFloat:&coords[0]];
            [scanner scanFloat:&coords[1]];
            [tempTextCoordData appendBytes:coords length:sizeof(coords)];
        }
        else if ([type isEqualToString:@"vn"])
        {
            //normal
            GLfloat coords[3];
            [scanner scanFloat:&coords[0]];
            [scanner scanFloat:&coords[1]];
            [scanner scanFloat:&coords[2]];
            [tempNormalData appendBytes:coords length:sizeof(coords)];
        }
        else if ([type isEqualToString:@"f"])
        {
            //face
            int count = 0;
            NSString *indexString = nil;
            while (![scanner isAtEnd])
            {
                count ++;
                [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&indexString];
                
                NSArray *parts = [indexString componentsSeparatedByString:@"/"];
                
                GLuint fIndex = uniqueIndexStrings;
                NSNumber *index = indexStrings[indexString];
                if (index == nil)
                {
                    uniqueIndexStrings ++;
                    indexStrings[indexString] = @(fIndex);
                    
                    GLuint vIndex = [parts[0] intValue];
                    tempPointer = reinterpret_cast<char*>(const_cast<void*>(tempVertexData.bytes));
                    tempPointer = tempPointer + (vIndex - 1) * sizeof(GLfloat) * 3;
                    [vertexData appendBytes:(void*)tempPointer length:sizeof(GLfloat) * 3];
                    
                    if ([parts count] > 1)
                    {
                        GLuint tIndex = [parts[1] intValue];
                        tempPointer = reinterpret_cast<char*>(const_cast<void*>(tempTextCoordData.bytes));
                        tempPointer = tempPointer + (tIndex - 1) * sizeof(GLfloat) * 2;
                        if (tIndex) [textCoordData appendBytes:(void*)tempPointer length:sizeof(GLfloat) * 2];
                    }
                    
                    if ([parts count] > 2)
                    {
                        GLuint nIndex = [parts[2] intValue];
                        tempPointer = reinterpret_cast<char*>(const_cast<void*>(tempNormalData.bytes));
                        tempPointer = tempPointer + (nIndex - 1) * sizeof(GLfloat) * 3;
                        if (nIndex) [normalData appendBytes:(void*)tempPointer length:sizeof(GLfloat) * 3];
                    }
                }
                else
                {
                    fIndex = [index unsignedLongValue];
                }
                
                if (count > 3)
                {
                    //face has more than 3 sides
                    //so insert extra triangle coords
                    tempPointer = reinterpret_cast<char*>(const_cast<void*>(faceIndexData.bytes));
                    tempPointer = tempPointer + faceIndexData.length - sizeof(GLuint) * 3;
                    [faceIndexData appendBytes:(void*)tempPointer length:sizeof(GLuint)];
                    
                    tempPointer = reinterpret_cast<char*>(const_cast<void*>(faceIndexData.bytes));
                    tempPointer = tempPointer + faceIndexData.length - sizeof(GLuint) * 2;
                    [faceIndexData appendBytes:(void*)tempPointer length:sizeof(GLuint)];
                }
                
                [faceIndexData appendBytes:&fIndex length:sizeof(GLuint)];
            }
            
        }
        //TODO: more
    }
    while (![lineScanner isAtEnd]);
    
    //release temporary storage
    
    //copy elements
    elementCount = [faceIndexData length] / sizeof(GLuint);
    const GLuint *faceIndices = (const GLuint *)faceIndexData.bytes;
    if (elementCount > USHRT_MAX)
    {
        elementType = GL_UNSIGNED_INT;
        elementSize = sizeof(GLuint);
        elements = malloc([faceIndexData length]);
        memcpy(elements, faceIndices, [faceIndexData length]);
    }
    else if (elementCount > UCHAR_MAX)
    {
        elementType = GL_UNSIGNED_SHORT;
        elementSize = sizeof(GLushort);
        elements = malloc([faceIndexData length] / 2);
        for (GLuint i = 0; i < elementCount; i++)
        {
            ((GLushort *)elements)[i] = faceIndices[i];
        }
    }
    else
    {
        elementType = GL_UNSIGNED_BYTE;
        elementSize = sizeof(GLubyte);
        elements = malloc([faceIndexData length] / 4);
        for (GLuint i = 0; i < elementCount; i++)
        {
            ((GLubyte *)elements)[i] = faceIndices[i];
        }
    }
    
    //copy vertices
    componentCount = 3;
    vertexCount = [vertexData length] / (3 * sizeof(GLfloat));
    vertices = (GLfloat*)malloc([vertexData length]);
    memcpy(vertices, vertexData.bytes, [vertexData length]);
    
    //copy texture coords
    if ([textCoordData length])
    {
        texCoords = (GLfloat*)malloc([textCoordData length]);
        memcpy(texCoords, textCoordData.bytes, [textCoordData length]);
    }
    
    //copy normals
    if ([normalData length])
    {
        normals = (GLfloat*)malloc([normalData length]);
        memcpy(normals, normalData.bytes, [normalData length]);
    }
    
    //success
    return true;
}

- (void) dealloc
{
    free(vertices);
    free(texCoords);
    free(normals);
    free(elements);
}

- (GLfloat*) getVertices { return vertices; }
- (GLfloat*) getTexCoords { return texCoords; }
- (GLfloat*) getNormals { return normals; }
- (void*) getElements { return elements; }

- (GLuint) getComponentCount { return componentCount; }
- (GLuint) getVertexCount { return vertexCount; }
- (GLuint) getElementCount { return elementCount; }
- (GLuint) getElementSize { return elementSize; }
- (GLuint) getElementType { return elementType; }

- (float) getDiffuse { return diffuse; }
- (float) getAmbient { return ambient; }
- (float) getSpecular { return specular; }
- (float) getSpecularPower { return specularPower; }

- (int) getTextureID:(int)num
{
    if (num >= 0 && num < textures.size())
        return textures[num].textureID;
    return 0;
}

@end
