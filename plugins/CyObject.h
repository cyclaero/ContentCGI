//  CyObject.h
//  Responder Delegate plugins
//
//  Created by Dr. Rolf Jansen on 2018-05-15.
//  Copyright © 2018 Dr. Rolf Jansen. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
//  OF THE POSSIBILITY OF SUCH DAMAGE.


#import <objc/Object.h>


#pragma mark ••• Objective-C root class CyObject •••
#if __PTR_WIDTH__ == 32
   #pragma pack(4)
#else
   #pragma pack(8)
#endif

__attribute__((objc_root_class))
@interface CyObject
{
   Class isa;
   int   refcount;
}

+ (Class)class;
+ (Class)superclass;
+ (id)allocWithZone:(void *)zone;
+ (id)alloc;
+ (id)new;

- (Class)class;
- (Class)superclass;

- (id)init;
- (id)copy;
- (id)copyWithZone:(void *)zone;

- (id)retain;
- (void)release;
- (void)dealloc;

- (id)performSelector:(SEL)aSelector;
- (id)performSelector:(SEL)aSelector withObject:(id)anObject;
- (id)performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject;

- (BOOL)isKindOfClass:(Class)aClass;
- (BOOL)isMemberOfClass:(Class)aClass;
- (BOOL)respondsToSelector:(SEL)aSelector;

@end

#pragma pack()
