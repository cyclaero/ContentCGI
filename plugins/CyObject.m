//  CyObject.m
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


#import "CyObject.h"


@implementation CyObject

#pragma mark ••• Class Methods •••

+ (Class)class
{
   return self;
}

+ (Class)superclass
{
  return class_getSuperclass(self);
}

+ (id)allocWithZone:(void *)zone
{
   return class_createInstance(self, 0);
}

+ (id)alloc
{
   return [self allocWithZone:NULL];
}

+ (id)new
{
   return [[self alloc] init];
}


#pragma mark ••• Instance Methods •••

- (Class)class
{
   return object_getClass(self);
}

- (Class)superclass
{
  return class_getSuperclass(object_getClass(self));
}

- (id)init
{
   return self;
}

- (id)copy
{
   return [self copyWithZone:NULL];
}

- (id)copyWithZone:(void *)zone
{
   return self;
}

- (id)retain
{
   __sync_fetch_and_add(&refcount, 1);
   return self;
}

- (void)release
{
   if (__sync_sub_and_fetch(&refcount, 1) < 0)
      [self dealloc];
}

- (void)dealloc
{
   object_dispose(self);
}

- (id)performSelector:(SEL)aSelector
{
   return objc_msgSend(self, aSelector);
}

- (id)performSelector:(SEL)aSelector withObject:(id)anObject
{
   return objc_msgSend(self, aSelector, anObject);
}

- (id)performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject
{
   return objc_msgSend(self, aSelector, anObject, anotherObject);
}

- (BOOL)isKindOfClass:(Class)aClass
{
   Class me = object_getClass(self);

   while (me != nil)
   {
      if (aClass == me)
         return YES;

      me = class_getSuperclass(me);
   }

   return NO;
}

- (BOOL)isMemberOfClass:(Class)aClass
{
   return (object_getClass(self) == aClass) ? YES : NO;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
   return class_respondsToSelector([self class], aSelector);
}

@end
