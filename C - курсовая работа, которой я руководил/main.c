#include <stdio.h>
#include <stdlib.h>
#include <direct.h>
#include <string.h>
#include <math.h>
struct Atom {
    float x,y,z;
    char at[4];
    };
struct AminoAcid {
    struct Atom atom[25];
    char catom;
    char name;
    char head[17];
    char type[17];
    };
struct Tree {
    int begin, end;
    };
struct File{
    int t, h1, h2;
};
char types[11][5] = {"_ML2", "_ML1", "_MMM", "_MR1", "_MR2", "_PL2", "_PL1", "_PPP", "_PR1", "_PR2", "_UUU"};
char types_for_files[11][5] = {"_PL2", "_PL1", "_P", "_PR1", "_PR2", "_ML2", "_ML1", "_M", "_MR1", "_MR2", "_U"};
char aat[]="ACDEFGHIKLMNPQRSTVWY";
char aat3[21][5] = {"_ALA", "_CYS", "_ASP", "_GLU", "_PHE", "_GLY", "_HIS", "_ILE", "_LYS", "_LEU", "_MET", "_ASN", "_PRO", "_GLN", "_ARG", "_SER", "_THR", "_VAL", "_TRP", "_TYR", "\0"};
char t[67][9];
char t_for_files[67][9];
void dist(const struct AminoAcid *aa1, const struct AminoAcid *aa2, float *dm, int *dca) {
    register char i, ii;
    *dm = 100000;
    float d;
    for (i = 0; i < aa1->catom; ++i)
        for (ii = 0; ii < aa2->catom; ++ii) {
            d = pow(aa1->atom[i].x - aa2->atom[ii].x, 2) + pow(aa1->atom[i].y - aa2->atom[ii].y, 2) + pow(aa1->atom[i].z - aa2->atom[ii].z, 2);
            if (d < *dm)
                *dm = d;
            if ((strcmp(aa1->atom[i].at, aa2->atom[ii].at) == 0) && (strcmp(aa1->atom[ii].at, "CA") == 0))
                *dca = (int) floorf(sqrtf(d));
        }
}
void TtoI(const char s1[5], const char s2[5], struct File *f) {
    register int flag, i;
    flag = 0;
    char s3[9], s4[9];
    sprintf(s3, "%s%s", s1, s2);
    sprintf(s4, "%s%s", s2, s1);
    for (i = 0; flag == 0; ++i)
        if ((0 == strcmp(t[i], s3)) || (strcmp(t[i], s4) == 0)) {
            //if (strcmp(t[i], s4) == 0) {
            if (((strcmp(t[i], s4) == 0) && (strcmp(s3, s4) != 0)) || ((strcmp(s3, s4) == 0) && (f->h1 > f->h2))) {
                int temp = f->h1;
                f->h1 = f->h2;
                f->h2 = temp;
            }
            f->t = i;
            if (f->t > 54) {
                f->h2 = 20;
                if (f->t == 65)
                    f->h1 = 20;
            }
            flag = 1;
        }
}
int AAtoI(const char c) {
    int i;
    for (i = 0; i < 20; ++i)
        if (aat[i] == c)
            return i;
    exit(7);
}
int AAtoI3(const char s[17], const int n) {
    int i;
    char ss[5];
    strncpy(ss, s + n, 4);
    ss[4] = '\0';
    for (i = 0; i < 21; ++i)
        if (0 == strcmp(aat3[i], ss))
            return i;
    exit(8);
}
int triangle[20] = {0, 19, 37, 54, 70, 85, 99, 112, 124, 135, 145, 154, 162, 169, 175, 180, 184, 187, 189, 190};
static inline int ItoTr(const int i, const int j) {
    return (triangle[((i>j)?j:i)] + ((i>j)?i:j));
}
int FtoI(const register struct File f) {
    if (f.t < 55)
        return f.t * 400 + f.h1 * 20 + f.h2;
    else if (f.t < 65)
        return 22000 + (f.t - 55) * 20 + f.h1;
    else
        return 22200;
}
void ItoF(const register int i, struct File *f) {
    register div_t d;
    if (i < 22000) {
        d = div(i, 400);
        f->t = d.quot;
        d = div(d.rem, 20);
        f->h1 = d.quot;
        f->h2 = d.rem;
    } else if (i < 22200) {
        d = div(i-22000, 20);
        f->t = 55 + d.quot;
        f->h1 = d.rem;
        f->h2 = 20;
    } else {
        f->t = (i == 22201)?66:65;
        f->h1 = 20;
        f->h2 = 20;
    }
}
int main() {
    // claim variables
    char path[256];
    char s[100];
    register int i;
    register FILE *f, *log;
    char cd[256]; // current directory of program
    char names[10000][8]; // proteins` names
    char path_in[256]; // directory of 'in' contacts
    char path_out[256]; // directory of 'between' contacts
    int count[28]; // counts of contacts in file
    register int *temp; // some
    register int temp_; // optimization
    struct Tree trees[10]; // array of trees
    int ctrees; // count of trees
    int dca; // dist of CA`s
    float dm; // dist min
    char type1[5], type2[5]; // temp types
    int tr; // keep point in file
    struct File tf; // temp File var
    int ti; // temp index of file
    int cc = 0; // counter of contacts
    int tree, tree1, tree2; // current tree
    struct Atom atom; // for pdb reading
    register int aa1; // for pdb count
    register int aa2; // for array
    int aa3; // for pdb current
    char c;
    int length; // of protein
    int ct = 0; // count of types
    int ii;
    int **files = (int **) calloc(44404, sizeof(int)); // matrix of pointers to files in memory
    register char *vf = (char *) calloc(25*1024, sizeof(char)); // virtual file
    register int l; // length of vf
    // create log file
    if ((log = fopen("elmatrix.log", "at")) == NULL)
        printf("\nError! Can't open/create elmatrix.log!\n");
    fprintf(log, "\n__________NEW SESSION__________\n");
    // read config file - distance borders
    getcwd(cd, 255);
    sprintf(path, "%s\\elmatrix.cfg", cd);
    if ((f = fopen(path, "r")) == NULL) {
        fprintf(log, "\nError! No CFG!\n");
        exit(1);
    }
    float dmin, dmax;
    fscanf(f, "%f %f", &dmin, &dmax);
    fclose(f);
    fprintf(log, "Dist. min = %.1f\nDist. max = %.1f\n", dmin, dmax);
    dmin = (float) pow(dmin, 2);
    dmax = (float) pow(dmax, 2);
    // read names
    sprintf(path, "%s\\input\\elmatrix.inp", cd);
    if ((f = fopen(path, "r")) == NULL) {
        fprintf(log, "\nError! No Names!\n");
        exit(9);
    }
    for (i = 0; fgets(names[i], 8, f); i++) names[i][6] = '\0';
    int pr_count = i;
    //for (i = 0; i < pr_count; printf("%i: \'%s\"\n", i, names[i++]));
    fclose(f);
    fprintf(log, "There are %i proteins\n", pr_count);
    // form combs with types
    for (i = 0; i < 11; i++) {
        for (ii = 0; ii <= i; ii++) {
            sprintf(t[ct], "%s%s", types[ii], types[i]);
            sprintf(t_for_files[ct++], "%s%s", types_for_files[ii], types_for_files[i]);
            //printf("%i: %s\n", ct-1, t[ct-1]);
        }
    }
    t[66][0] = '\0';
    int cur_pr;
    for (cur_pr = 0; cur_pr < pr_count; cur_pr++) { // for each protein
        // read sqr, claim aa and find out length of protein
        printf("Processing protein \'%s\'... ", names[cur_pr]);
        fprintf(log, "__PROTEIN \'%s\' (%i of %i: %i%%)__\n", names[cur_pr], cur_pr + 1, pr_count, (cur_pr + 1) * 100 / pr_count);
        // create array of aa
        sprintf(path, "%s\\input\\sqr\\%s.sqr", cd, names[cur_pr]);
        if ((f = fopen(path, "r")) == NULL) {
            fprintf(log, "\nError! No SQR!\n");
            exit(2);
        }
        fgets(s, 100, f);
        sscanf(strstr(s,"nu_res=")+7,"%i",&length);
        i = 0;
        struct AminoAcid *aa = (struct AminoAcid *) calloc(length, sizeof(struct AminoAcid));
        while ((c = getc(f)) != '*') // while it isn`t '*'
            if ((c != ' ') && (c != '\n')) // and not space symbol
                aa[i++].name = c; // calm next aa
        fclose(f);
        // read pdb and fill aa array with atoms
        sprintf(path, "%s\\input\\pdb\\%s.pdb", cd, names[cur_pr]);
        if ((f = fopen(path, "r")) == NULL) {
            fprintf(log, "\nError! No PDB!\n");
            exit(3);
        }
        aa1 = 0; // for pdb count
        aa2 = -1; // for array
        aa3 = 0; // for pdb current
        while (fgets(s, 100, f))
            if (strncmp(s,"ATOM",4) == 0) {
                sscanf (s+4, "%*i %s %*s %*s %i %f %f %f", atom.at, &aa3, &atom.x, &atom.y, &atom.z);
                //printf("%s %f %f %f\n",atom.at,atom.x,atom.y,atom.z);
                if (aa1 < aa3) {
                    aa1 = aa3;
                    aa[++aa2].catom = 0;
                }
                strcpy(aa[aa2].atom[aa[aa2].catom].at, atom.at);
                aa[aa2].atom[aa[aa2].catom].x = atom.x;
                aa[aa2].atom[aa[aa2].catom].y = atom.y;
                aa[aa2].atom[aa[aa2].catom].z = atom.z;
                aa[aa2].catom++;
            }
        /*for (aa1 = 0; aa1<length; aa1++) {
            for (aa2 = 0; aa2 < aa[aa1].catom; aa2++)
                printf("%i (%i): %s %f %f %f\n", aa1+1, aa2+1, aa[aa1].atom[aa2].at, aa[aa1].atom[aa2].x, aa[aa1].atom[aa2].y, aa[aa1].atom[aa2].z);
        }//*/
        fclose(f);
        // read res and set types
        sprintf(path, "%s\\input\\res\\%s.res", cd, names[cur_pr]);
        if ((f = fopen(path, "r")) == NULL) {
            fprintf(log, "\nError! No RES!\n");
            exit(4);
        }
        fprintf(log, "__RES__\n");
        while (fgets(s, 100, f))
            if ((s[1] == '-') || (s[1] == '+')) {
                sscanf (s+12, "%i",&ii);
                for (i = -2; i < 3; i++) // for each surrounding aa
                    if ((ii-1+i < length) && (ii-1+i >= 0)) {
                        strcat(aa[ii-1+i].type, types[i+((s[1] == '+')?2:7)]);
                        strcat(aa[ii-1+i].head, aat3[AAtoI(aa[ii-1].name)]);
                    }
            }
        for (i = 0; i < length; i++) {
            if (aa[i].type[0] != '_') {
                strcpy(aa[i].type, types[10]);
                aa[i].head[0] = '\0';
            }
            fprintf(log, "%i(%s): %s (%s)\n", i + 1, aat3[AAtoI(aa[i].name)]+1, aa[i].type, aa[i].head);
        }
        fclose(f);
        // read eli and make trees
        sprintf(path, "%s\\input\\eli\\%s.eli", cd, names[cur_pr]);
        if ((f = fopen(path, "r")) == NULL) {
            fprintf(log, "\nError! No ELI!\n");
            exit(5);
        }
        ctrees = 0;
        while (fscanf(f, "%i", &trees[ctrees].end) != EOF) {
            trees[ctrees].begin = (ctrees == 0)? 1: (trees[ctrees - 1].end + 1);
            if (trees[ctrees].end != 0) {
                trees[ctrees + 1].begin = trees[ctrees].end--;
                ctrees++;
            }
        }
        trees[ctrees++].end = length;
        fprintf(log, "__TREES__\n");
        for (i = 0; i < ctrees; i++) fprintf(log, "%i: %i %i\n", i + 1, trees[i].begin, trees[i].end);
        fclose(f);
        fprintf(log, "__CONTACTS__\n");
        if (ctrees > 1) {
            // form matrix between trees
            files[22201] = (int *) calloc(5250, sizeof(int)); // summary file for 'between'
            cc = 0;
            for (tree1 = 0; tree1 < ctrees - 1; tree1++)
                for (tree2 = tree1 + 1; tree2 < ctrees; tree2++)
                    for (aa1 = trees[tree1].begin - 1; aa1 < trees[tree1].end; aa1++) // choose aa1 in tree1
                        for (aa2 = trees[tree2].begin - 1; aa2 < trees[tree2].end; aa2++) { //choose aa2 in tree2
                            dist(aa + aa1, aa + aa2, &dm, &dca); // calculate distance
                            if ((dm <= dmax) && (dm >= dmin)) { // if there is contact
                                tr = 210*dca + ItoTr(AAtoI(aa[aa1].name), AAtoI(aa[aa2].name));
                                files[22201][tr]++; // write in 'matrix_all' file
                                fprintf(log, "out #%i: (%i, %i) name[%c %c] dist = %i\n", ++cc, aa1+1, aa2+1, aa[aa1].name, aa[aa2].name, dca);
                                for (i = 0; i < strlen(aa[aa1].type); i += 4) { // for every type of aa1
                                    for (ii = 0; ii < strlen(aa[aa2].type); ii += 4) { // for every type of aa2
                                        strncpy(type1, aa[aa1].type+i, 4); // aa1 type
                                        type1[4] = '\0'; // ending
                                        tf.h1 = AAtoI3(aa[aa1].head, i); // head 1
                                        strncpy(type2, aa[aa2].type+ii, 4); // aa2 type
                                        type2[4] = '\0';  // ending
                                        tf.h2 = AAtoI3(aa[aa2].head, ii); // head 2
                                        TtoI(type1, type2, &tf); // typing pair
                                        // create file in memory
                                        ti = FtoI(tf);
                                        if (files[ti] == NULL) // create file if it isn`t exist
                                            files[ti] = (int *) calloc(5250, sizeof(int));
                                        files[ti][tr]++; // inc number
                                        fprintf(log, "        %s%s%s\n", t_for_files[tf.t] + 1, aat3[tf.h1], aat3[tf.h2]);
                                    }
                                }
                            }
                        }
        }
        // form matrix in trees
        files[44403] = (int *) calloc(5250, sizeof(int)); // summary file for 'in'
        cc = 0;
        for (tree = 0; tree < ctrees; tree++) // choose tree
            for (aa1 = trees[tree].begin-1; aa1 < trees[tree].end - 1; aa1++)
                for (aa2 = aa1 + 1; aa2 < trees[tree].end; aa2++) {
                    dist(aa + aa1, aa + aa2, &dm, &dca); // calculate distance
                    if ((dm <= dmax) && (dm >= dmin)) { // if there is contact
                        tr = 210*dca + ItoTr(AAtoI(aa[aa1].name), AAtoI(aa[aa2].name)); // get point in tables
                        files[44403][tr]++; // write in 'matrix_all' file
                        fprintf(log, "in #%i: (%i, %i) name[%c %c] dist = %i\n", ++cc, aa1+1, aa2+1, aa[aa1].name, aa[aa2].name, dca);
                        for (i = 0; i < strlen(aa[aa1].type); i += 4) { // for every type of aa1
                            for (ii = 0; ii < strlen(aa[aa2].type); ii += 4) { // for every type of aa2
                                strncpy(type1, aa[aa1].type+i, 4); // aa1 type
                                type1[4] = '\0'; // ending
                                tf.h1 = AAtoI3(aa[aa1].head, i);
                                strncpy(type2, aa[aa2].type+ii, 4); // aa2 type
                                type2[4] = '\0'; // ending
                                tf.h2 = AAtoI3(aa[aa2].head, ii); // head 2
                                TtoI(type1, type2, &tf); // typing pair
                                // create file in memory
                                ti = 22202 + FtoI(tf);
                                if (files[ti] == NULL) // create file if it isn`t exist
                                    files[ti] = (int *) calloc(5250, sizeof(int));
                                files[ti][tr]++; // inc number
                                fprintf(log, "        %s%s%s\n", t_for_files[tf.t] + 1, aat3[tf.h1], aat3[tf.h2]);

                            }
                        }
                    }
                }
        free(aa);
        // creating files for contacts 'between' and 'in' trees
        sprintf(path, "%s\\output", cd);
        mkdir(path); // make 'output' folder
        sprintf(path_in, "%s\\%s in[%.1lf-%.1lf]", path, names[cur_pr], sqrtf(dmin), sqrtf(dmax));
        mkdir(path_in); // make folder with 'in' contacts
        if (ctrees > 1) {
            sprintf(path_out, "%s\\%s out[%.1lf-%.1lf]", path, names[cur_pr], sqrtf(dmin), sqrtf(dmax));
            mkdir(path_out); // make folder with 'between' contacts
        }
        for (i = ((ctrees > 1)? 0: 22202); i < 44404; ++i) { // for each file in memory
            if (files[i] != NULL) { // that DOES exist
                // write virtual file
                temp = files[i]; // pointer to current table in file
                l = 0;
                for (dca = 0; dca < 25; ++dca) { // for each matrix in file
                    count[dca] = 0;
                    for (aa1 = 0; aa1 < 210; ++aa1) // sum contacts in matrix
                        count[dca] += temp[aa1];
                    l += sprintf(vf + l, "CONTACT all dist_CA=%i sum_contacts=%i\n\n", dca, count[dca]); // header of matrix
                    for (aa1 = 0; aa1 < 20; ++aa1) { // printing horizontal line of aa
                        vf[l++] = '\t';
                        vf[l++] = aat[aa1];
                    }
                    vf[l++] = '\n';
                    temp_ = -1;
                    // print current matrix
                    for (aa1 = 0; aa1 < 20; ++aa1) { // rows
                        vf[l++] = aat[aa1];
                        for (aa2 = 0; aa2 < aa1; ++aa2) { // columns filled with zeros
                            vf[l++] = '\t';
                            vf[l++] = '0';
                        }
                        for (aa2 = aa1; aa2 < 20; ++aa2) // meaning columns
                            l += sprintf(vf + l, "\t%i", temp[++temp_]);
                        vf[l++] = '\n';
                    }
                    temp += 210;
                }
                count[25] = 0;
                count[26] = 0;
                count[27] = 0;
                for (aa1 = 0; aa1 < 25; aa1++) { // count sum of file
                    count[25] += count[aa1];
                    if (count[aa1] > count[26]) { // and it`s maximal matrix
                        count[27] = aa1;
                        count[26] = count[aa1];
                    }
                }
                l += sprintf(vf + l, "SUMMARY contacts=%i cont_ds_max=%i\n", count[25], count[27]); // summary line
                vf[l++] = '\0';
                // get data for file from counter
                ItoF(((i < 22202)? i: i - 22202), &tf);
                // create file
                sprintf(path, "%s\\matrix_all%s%s%s.txt", ((i < 22202)? path_out: path_in), t_for_files [tf.t], aat3[tf.h1], aat3[tf.h2]);
                f = fopen(path, "wt");
                if (f == NULL) {
                    printf("\nError! Fail to create file \"%s!\"", path);
                    exit(6);
                }
                fputs(vf, f); // write real file
                fclose(f); // close
                // renew for next protein
                free(files[i]);
                files[i] = NULL;
            }
        }
        // end
        printf("Done! (%i of %i: %i%%)\n", cur_pr + 1, pr_count, (cur_pr + 1) * 100 / pr_count);
    }
    free(files); // free map of matrix
    free(vf); // free virtual file
    exit(0);
}
