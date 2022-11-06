#coding=utf8
from math import *

def tran(x): # транспонирование
    return list(zip(*x))

def l(x): # итерация по индексам списка
    return xrange(len(x))

def mult(a,b): # умножение матриц
    def sum(x,y):
        s = 0
        for i in l(x):
            s += x[i]*y[i]
        return s
    return [[sum(a[i],tran(b)[j]) for j in l(b[0])] for i in l(a)]

def mult_l(x,i,k): # умножение столбца (пока не строки)
    for j in l(x[i]):
        x[i][j]*=k
    return x

def mult_n(x,k): # умножение на число
    return [[j*k for j in i] for i in x]

def sum(a,b,m=0): # сумма матриц
    return [[a[i][j]+b[i][j]*(-1)**m for j in l(a)] for i in l(a)]

def minor(x,i,j): # матрица минора
    return [x[c][:j]+x[c][j+1:] for c in l(x) if c!=i]

def det(x): # определитель матрицы
    if len(x)>1:
        d = 0
        for i in l(x):
            d += ((-1)**i)*x[i][0]*det(minor(x,i,0))
        return d
    else:
        return x[0][0]

def det_n(x,b,i): # определитель матрицы с подставленным столбцом (для м. крамера)
    x = tran(x)
    x[i] = b
    return det(x)

def adj(x): # матрица алгебраических дополнений
    return [[det(minor(x,c,d))*((-1)**(c+d)) for d in l(x)] for c in l(x)]

def inv(x): # обратная матрица
    return mult_n(tran(adj(x)),1./det(x))

def pow(x,n): # возведение матрицы в степень
    w = x
    for i in xrange(n):
        w = mult(w,x)
    return w

def get_e(i): # единичная матрица порядка i
    e = [[0 for j in range(i)] for k in range(i)]
    for g in range(i):
        e[g][g] = 1
    return e

def equal(a,b): # равенство матриц
    for i in l(a):
        for j in l(a[i]):
            d = a[i][j]-b[i][j]
            if round(d,-10)!=0.0:
                return False
    return True

def kramer(x,b): # решение системы крамером
    d = det(x)
    return [det_n(x,b,i)/d for i in l(x)]

def printm(x): # user-frendly печать матрицы
    for i in l(x):
        print('\t'.join(map(lambda a: str(a),x[i])))

"""def gauss(x): # метод гаусса
    i = j = 0
    while x[i][j]=0:
        if i<len(x):
            i+=1
        else:
            j+=1
            i=0
    for b in x:
        k = x[i][j]/b[0]
        for c in b:
            x[b][c]-=k*x[i][c]
        
"""

a = [[1,-11/3,-1/3],[2,2,2],[3/4,17/4,25/12]]
b = [[4,-12,0],[8,4,8],[3,12,7]]
c = [[4,-1,1],[0,3,0],[0,0,3]]

print(equal(mult(mult(b,inv(c)),c),b))
