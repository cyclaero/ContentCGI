//  interim.c
//  ContentCGI
//
//  Created by Dr. Rolf Jansen on 2018-05-08.
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
//  WARRANTIES OF MERCHANTABILITYAND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
//  OF THE POSSIBILITY OF SUCH DAMAGE.


#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include <stdarg.h>
#include <syslog.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <openssl/md5.h>
#include <openssl/sha.h>

#include "utils.h"
#include "interim.h"


#pragma mark ••• AVL Tree •••
#pragma mark ••• Value Data householding •••

static inline void releaseValue(Value *value)
{
   switch (-value->kind)   // dynamic data, has to be released
   {
      case String:
         if (value->custom_deallocate)
            value->custom_deallocate(VPR(value->s), value->offset, false);
         else
            deallocate(VPR(value->s), false);
         break;

      case Simple:
      case Data:
      case Dictionary:
         if (value->custom_deallocate)
            value->custom_deallocate(VPR(value->p), value->offset, false);
         else
            deallocate(VPR(value->p), false);
         break;
   }
}


static int balanceNode(Node **node)
{
   int   change = 0;
   Node *o = *node;
   Node *p, *q;

   if (o->B == -2)
   {
      if (p = o->L)                    // make the static analyzer happy
         if (p->B == +1)
         {
            change = 1;                // double left-right rotation
            q      = p->R;             // left rotation
            p->R   = q->L;
            q->L   = p;
            o->L   = q->R;             // right rotation
            q->R   = o;
            o->B   = +(q->B < 0);
            p->B   = -(q->B > 0);
            q->B   = 0;
            *node  = q;
         }

         else
         {
            change = p->B;             // single right rotation
            o->L   = p->R;
            p->R   = o;
            o->B   = -(++p->B);
            *node  = p;
         }
   }

   else if (o->B == +2)
   {
      if (q = o->R)                    // make the static analyzer happy
         if (q->B == -1)
         {
            change = 1;                // double right-left rotation
            p      = q->L;             // right rotation
            q->L   = p->R;
            p->R   = q;
            o->R   = p->L;             // left rotation
            p->L   = o;
            o->B   = -(p->B > 0);
            q->B   = +(p->B < 0);
            p->B   = 0;
            *node  = p;
         }

         else
         {
            change = q->B;             // single left rotation
            o->R   = q->L;
            q->L   = o;
            o->B   = -(--q->B);
            *node  = q;
         }
   }

   return change != 0;
}


static int pickPrevNode(Node **node, Node **exch)
{                                       // *exch on entry = parent node
   Node *o = *node;                     // *exch on exit  = picked previous value node

   if (o->R)
   {
      *exch = o;
      int change = -pickPrevNode(&o->R, exch);
      if (change)
         if (abs(o->B += change) > 1)
            return balanceNode(node);
         else
            return o->B == 0;
      else
         return 0;
   }

   else if (o->L)
   {
      Node *p = o->L;
      o->L = NULL;
      (*exch)->R = p;
      *exch = o;
      return p->B == 0;
   }

   else
   {
      (*exch)->R = NULL;
      *exch = o;
      return 1;
   }
}


static int pickNextNode(Node **node, Node **exch)
{                                       // *exch on entry = parent node
   Node *o = *node;                     // *exch on exit  = picked next value node

   if (o->L)
   {
      *exch = o;
      int change = +pickNextNode(&o->L, exch);
      if (change)
         if (abs(o->B += change) > 1)
            return balanceNode(node);
         else
            return o->B == 0;
      else
         return 0;
   }

   else if (o->R)
   {
      Node *q = o->R;
      o->R = NULL;
      (*exch)->L = q;
      *exch = o;
      return q->B == 0;
   }

   else
   {
      (*exch)->L = NULL;
      *exch = o;
      return 1;
   }
}


// CAUTION: The following recursive functions must not be called with name == NULL.
//          For performace reasons no extra error cheking is done.

Node *findTreeNode(const char *name, Node *node)
{
   if (node)
   {
      int ord = strcmp(name, node->name);

      if (ord == 0)
         return node;

      else if (ord < 0)
         return findTreeNode(name, node->L);

      else // (ord > 0)
         return findTreeNode(name, node->R);
   }

   else
      return NULL;
}

int addTreeNode(const char *name, ssize_t naml, Value *value, Node **node, Node **passed)
{
   static const Value zeros = {{.i = 0}, 0, 0, 0, NULL};

   Node *o = *node;

   if (o == NULL)                         // if the name is not in the tree
   {                                      // then add it into a new leaf
      if (o = allocate(sizeof(Node), default_align, true))
         if (o->name = allocate(naml+1, default_align, false))
         {
            strcpy(o->name, name);
            o->naml = naml;
            if (value)
               o->value = *value;
            *node = *passed = o;          // report back the new node into which the new value has been entered
            return 1;                     // add the weight of 1 leaf onto the balance
         }
         else
            deallocate(VPR(o), false);

      *passed = NULL;
      return 0;                           // Out of Memory situation, nothing changed
   }

   else
   {
      int change;
      int ord = strcmp(name, o->name);

      if (ord == 0)                       // if the name is already in the tree then
      {
         releaseValue(&o->value);         // release the old value - if kind is empty then releaseValue() does nothing
         o->value = (value) ? *value      // either store the new value or
                            :  zeros;     // zero-out the value struct
         *passed = o;                     // report back the node in which the value was modified
         return 0;
      }

      else if (ord < 0)
         change = -addTreeNode(name, naml, value, &o->L, passed);

      else // (ord > 0)
         change = +addTreeNode(name, naml, value, &o->R, passed);

      if (change)
         if (abs(o->B += change) > 1)
            return 1 - balanceNode(node);
         else
            return o->B != 0;
      else
         return 0;
   }
}

int removeTreeNode(const char *name, Node **node)
{
   Node *o = *node;

   if (o == NULL)
      return 0;                              // not found -> recursively do nothing

   else
   {
      int change;
      int ord = strcmp(name, o->name);

      if (ord == 0)
      {
         int    b = o->B;
         Node  *p = o->L;
         Node  *q = o->R;

         if (!p || !q)
         {
            releaseValue(&(*node)->value);
            deallocate_batch(false, VPR((*node)->name),
                                    VPR(*node), NULL);
            *node = (p > q) ? p : q;
            return 1;                        // remove the weight of 1 leaf from the balance
         }

         else
         {
            if (b == -1)
            {
               if (!p->R)
               {
                  change = +1;
                  o      =  p;
                  o->R   =  q;
               }
               else
               {
                  change = +pickPrevNode(&p, &o);
                  o->L   =  p;
                  o->R   =  q;
               }
            }

            else
            {
               if (!q->L)
               {
                  change = -1;
                  o      =  q;
                  o->L   =  p;
               }
               else
               {
                  change = -pickNextNode(&q, &o);
                  o->L   =  p;
                  o->R   =  q;
               }
            }

            o->B = b;
            releaseValue(&(*node)->value);
            deallocate_batch(false, VPR((*node)->name),
                                    VPR(*node), NULL);
            *node = o;
         }
      }

      else if (ord < 0)
         change = +removeTreeNode(name, &o->L);

      else // (ord > 0)
         change = -removeTreeNode(name, &o->R);

      if (change)
         if (abs(o->B += change) > 1)
            return balanceNode(node);
         else
            return o->B == 0;
      else
         return 0;
   }
}

void releaseTree(Node *node)
{
   if (node)
   {
      if (node->L)
         releaseTree(node->L);
      if (node->R)
         releaseTree(node->R);

      releaseValue(&node->value);
      deallocate_batch(false, VPR(node->name),
                              VPR(node), NULL);
   }
}

void serializeTree(Node *table[], uint *namColWidth, uint *m, Node *node)
{
   if (node)
   {
      if (node->L)
         serializeTree(table, namColWidth, m, node->L);

      table[(*m)++] = node;
      if (node->naml > *namColWidth)
         *namColWidth = (uint)node->naml;

      if (node->R)
         serializeTree(table, namColWidth, m, node->R);
   }
}


void printTree(Node *node, uint naml)
{
   if (node->L)
      printTree(node->L, naml);

   printf(" %*s: %s\n", naml, node->name, node->value.s);

   if (node->R)
      printTree(node->R, naml);
}


#pragma mark ••• Hash Table •••

// Table creation and release
Node **createTable(uint n)
{
   Node **table = allocate((n+2)*sizeof(Node *), default_align, true);
   if (table)
      *(uint *)table = n;
   return table;
}

void releaseTable(Node *table[])
{
   if (table)
   {
      uint i, n = 2 + *(uint *)&table[0];
      for (i = 2; i < n; i++)
         releaseTree(table[i]);
      deallocate(VPR(table), false);
   }
}


// Storing and retrieving values by name
Node *findName(Node *table[], const char *name, ssize_t naml)
{
   if (name && *name)
   {
      if (naml <= 0)
         naml = strvlen(name);
      uint n = *(uint *)&table[0];
      return findTreeNode(name, table[mmh3(name, naml)%n + 2]);
   }
   else
      return NULL;
}

Node *storeName(Node *table[], const char *name, ssize_t naml, Value *value)
{
   if (name && *name)
   {
      Node *passed;

      if (naml <= 0)
         naml = strvlen(name);
      uint n = *(uint *)&table[0];
      addTreeNode(name, naml, value, &table[mmh3(name, naml)%n + 2], &passed);
      (*(uint *)&table[1])++;

      return passed;
   }
   else
      return NULL;
}

void removeName(Node *table[], const char *name, ssize_t naml)
{
   if (name && *name)
   {
      if (naml <= 0)
         naml = strvlen(name);
      uint tidx = mmh3(name, naml) % *(uint*)&table[0] + 2;
      Node *node = table[tidx];
      if (node)
      {
         if (!node->L && !node->R)
         {
            releaseValue(&node->value);
            deallocate_batch(false, VPR(node->name),
                                    VPR(table[tidx]), NULL);
         }
         else
            removeTreeNode(name, &table[tidx]);

         (*(uint *)&table[1])--;
      }
   }
}


static void quicksort(Node *a[], int l, int r)
{
   char *m = a[(l + r)/2]->name;
   int   i = l, j = r;
   Node *b;

   do
   {
      while (strcmp(a[i]->name, m) < 0) i++;
      while (strcmp(a[j]->name, m) > 0) j--;
      if (i <= j)
      {
         b = a[i]; a[i] = a[j]; a[j] = b;
         i++; j--;
      }
   } while (j > i);

   if (l < j) quicksort(a, l, j);
   if (i < r) quicksort(a, i, r);
}


void printTable(Node *table[], uint *nameColWidth)
{
   uint  i, m = 0, n = 2 + *(uint *)&table[0];
   Node *sort[*(uint *)&table[1]];
   for (m = 0, i = 2; i < n; i++)
      if (table[i])
         serializeTree(sort, nameColWidth, &m, table[i]);

   if (m)
   {
      quicksort(sort, 0, m-1);
      for (i = 0; i < m; i++)
         printf(" %*s: %s\n", *nameColWidth, sort[i]->name, sort[i]->value.s);
   }
}

int sprintTable(Node *table[], uint *namColWidth, dynhdl output)
{
   if (output)
   {
      if (!output->buf)
         *output = newDynBuffer();

      uint  i, m = 0, n = 2 + *(uint *)&table[0];
      Node *sort[*(uint *)&table[1]];
      for (m = 0, i = 2; i < n; i++)
         if (table[i])
            serializeTree(sort, namColWidth, &m, table[i]);

      if (m)
      {
         quicksort(sort, 0, m-1);

         char namColumn[1+*namColWidth+5+1];
         for (i = 0; i < m; i++)
         {
            dynAddString(output, namColumn, snprintf(namColumn, 3+*namColWidth+2+1, "   %*s: ", *namColWidth, sort[i]->name));
            dynAddString(output, sort[i]->value.s, strvlen(sort[i]->value.s));
            dynAddString(output, "\n", 1);
         }
      }

      return dynlen(*output);
   }
   else
      return 0;
}
