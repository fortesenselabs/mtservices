
void OnInit() {

   int a = 0, b = 1, c = 2, d = 3, e = 0;
   
   int abcde[5];
   
   abcde[0] = 0;
   abcde[1] = 1;
   abcde[2] = 2;
   abcde[3] = 3;
   abcde[4] = 4;
   
   // o
   
   int edcba[5] = {0, 1, 2, 3, 4};
   
   Print("abcde: ", abcde[0], " ", abcde[1], " ", abcde[2], " ", abcde[3], " ", abcde[4]);
   Print("edcba: ", edcba[0], " ", edcba[1], " ", edcba[2], " ", edcba[3], " ", edcba[4]);
   
   char chain[10] = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'};
   
   Print(chain[0], " ", chain[1], " ", chain[2], " ", chain[3], " ", chain[4], " ", chain[5], " ", chain[6], " ", chain[7], " ", chain[8], " ", chain[9]);
}