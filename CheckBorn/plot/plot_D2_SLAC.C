#include <fstream>
#include "ReadFile.h"
using namespace std;

void plot_D2_SLAC()
{
     Double_t D2_x[1][MAXBIN],D2_Q2[1][MAXBIN],D2_Born[1][MAXBIN],D2_Born1[1][MAXBIN];
     Double_t D2_ratio[1][MAXBIN];

     for(int ii=0;ii<1;ii++){
	 for(int jj=0;jj<MAXBIN;jj++){
             D2_x[ii][jj]=0.0; D2_Q2[ii][jj]=0.0; D2_Born[ii][jj]=0.0;D2_Born1[ii][jj]=0.0;
	     D2_ratio[ii][jj]=0.0;
     }}

   TString Yfile;
   int kin[1]={0};
   for(int ii=0;ii<1;ii++){
       Yfile="INEFT/marathon.out";
       ReadYield(Yfile,kin[ii],D2_x,D2_Q2,D2_Born); 
       Yfile="f1f217/marathon.out";
       ReadYield(Yfile,kin[ii],D2_x,D2_Q2,D2_Born1); 
   }

   TGraph *hborn=new TGraph();
   TGraph *hborn1=new TGraph();
   TGraph *hratio=new TGraph();
    
   int nn=0;
   for(int ii=0;ii<1;ii++){
       for(int jj=0;jj<MAXBIN;jj++){
	   if(D2_x[ii][jj]==0 || D2_Q2[ii][jj]>13)continue;
           hborn->SetPoint(nn,D2_x[ii][jj],D2_Born[ii][jj]);
           hborn1->SetPoint(nn,D2_x[ii][jj],D2_Born1[ii][jj]);

           if(D2_Born1[ii][jj]>0)D2_ratio[ii][jj]=D2_Born1[ii][jj]/D2_Born[ii][jj];
           hratio->SetPoint(nn,D2_x[ii][jj],D2_ratio[ii][jj]);
           nn++;
       }
   } 

   TCanvas *c1=new TCanvas("c1","c1",1500,1500);
   c1->Divide(2,1);
   c1->cd(1);
   TMultiGraph *mg1=new TMultiGraph();
   hborn->SetMarkerStyle(8);
   hborn->SetMarkerColor(4);
   hborn1->SetMarkerStyle(8);
   hborn1->SetMarkerColor(2);
   mg1->Add(hborn);
   mg1->Add(hborn1);
   mg1->Draw("AP");
   mg1->SetTitle("D2 born cross section;xbj;born");

   auto leg1=new TLegend(0.7,0.6,0.81,0.81);
   leg1->AddEntry(hborn,"Bodek","P");
   leg1->AddEntry(hborn1,"f1f217","P");
   leg1->Draw();

   c1->cd(2);
   hratio->SetMarkerStyle(8);
   hratio->SetMarkerColor(4);
   hratio->Draw("AP");
   hratio->SetTitle("D2 f1f217/Bodek;xbj;"); 


}
