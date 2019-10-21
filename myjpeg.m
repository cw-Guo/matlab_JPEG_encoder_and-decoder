close all;
clc ;
clear all;

tic
K =10;%压缩倍率

%进行量化
Z = [16,11,10,16,24,40,51,61
    12,12,14,19,26,58,60,55
    14,13,16,24,40,57,69,56
    14,17,22,29,51,87,80,62
    18,22,37,56,68,109,103,77
    24,35,55,64,81,104,113,92
    49,64,78,87,103,121,120,101
    72,92,95,98,112,100,103,99];

i = imread("imageA.bmp");%读取图像
%i = rgb2gray(i);
%imshow(i);
%i = double(i);
I=i;

%i = i-128;
[h0,w0]=size(i);%读取尺寸信息

%padding
H = ceil(h0/8)*8;
W = ceil(w0/8)*8;
%padding h using the last column
if mod(h0,8)~=0
    for m=h0:H
        i(m,:)=i(h0,:);
    end
end


 %padding w using the last line
 
if mod(w0,8)~=0
    for m=w0:W
        i(:,m)=i(:,w0);
    end
end

%pading 完成

%接下来进行图像压缩部分
[H1,W1]=size(i);
nH=H/8;%行里多少块
nW=W/8;%列里多少块
idx=0;
%block(1:8,1:8,1:nH*nW)=zeros(8,8,nH*nW);%预先分配空间，可以加快运行速度
%Qblock(1:8,1:8,1:nH*nW)=zeros(8,8,nH*nW);
Zline1 = [];%预分配空间 存储数据流
for j=1:nH
    for k=1:nW
    idx=idx+1;
    
    block(:,:,idx)=i(((j-1)*8+1:(j-1)*8+8),((k-1)*8+1:(k-1)*8+8));%分块
    DCTblock(:,:,idx) = dct2(block(:,:,idx));%进行dct变换
    Qblock(:,:,idx) =round(DCTblock(:,:,idx)./(K*Z));%量化，矩阵之间用./ 
    
    a=0;%最后一个非零位置
    b=64;%索引
    
    Zline=zigzag(Qblock(:,:,idx));%zigzag %去除后续全部零的值
        while b~=0
            if Zline(b)~=0
                a=b;
                break;
            end 
        b=b-1;
        end
    Zline1 =[Zline1,a,Zline(1:a)];
    end
end

toc            
%至此，主要压缩部分已经完成 
%为了解压缩考虑，我们需要添加文件头部分

%文件头
%header 40位
%其中
%Height 16位
%Width  16位
%压缩率8位
header =[h0,w0,K,nH,nW,0,0,0];
Seq =[header,double(Zline1)];
%压缩完毕

Seq0 = Seq; %假设接收无误差
%读取header 
rH = Seq0(4);
rW = Seq0(5);
rh0 = Seq0(1); %原始大小h
rw0 = Seq0(2); %原始大小w
rK = Seq0(3);  %压缩率
idx=0;
%文件头读取完毕之后 我们处理接受的编码流
base = 9;
for j = 1:rH
    for k =1:rW
        idx = idx +1;
        ra =Seq0(base+1:base+Seq0(base));
        rQblock(:,:,idx)=izigzag(ra);
        rDCTblock(:,:,idx)=rQblock(:,:,idx).*(rK*Z); %误差来源之二
        rblock(:,:,idx)=idct2(rDCTblock(:,:,idx));
        rimage((j-1)*8+1:j*8,(k-1)*8+1:k*8)=rblock(:,:,idx);
        base =Seq0(base)+base+1;
    end
end
rimage =round(rimage(1:rh0,1:rw0));
figure;
subplot(121),imshow(I),title("the image"); %观察一下原图
subplot(122),imshow(uint8(rimage)),title("image after being compressed");

%一些参数计算
origin_image = h0*w0*8;%bit
compress_image = length(Seq)*8;%bit 粗略估计
CR = origin_image./compress_image;
PSNR=10*log10(255*255/mean(mean((double(I)-double(rimage)).^2)));

disp(['When K=',num2str(K),':']);
disp(['PSNR:                 ',num2str(PSNR)]);
disp(['Original Bit:         ',num2str(origin_image),' bit']);
disp(['Compressed Bit:       ',num2str(compress_image),' bit']);
disp(['Compression Ratios:   ',num2str(CR)]);

function y=zigzag(a)
    zz=[1,2,9,17,10,3,4,11,18,25,33,26,19,12,5,6,13,20,27,34,41,49,42,35,28,21,14,7,...
        8,15,22,29,36,43,50,57,58,51,44,37,30,23,16,24,31,38,45,52,59,60,53,46,39,32,...
        40,47,54,61,62,55,48,56,63,64];
    aa = reshape(a,1,64);%转化成数据流
    y=aa(zz);% 数据流中的第zz个是对应的y中的
end

function y =izigzag(a)
        zz=[1,2,9,17,10,3,4,11,18,25,33,26,19,12,5,6,13,20,27,34,41,49,42,35,28,21,14,7,...
        8,15,22,29,36,43,50,57,58,51,44,37,30,23,16,24,31,38,45,52,59,60,53,46,39,32,...
        40,47,54,61,62,55,48,56,63,64];
        b = zeros(1,64); %开辟存储空间
        for i=1:length(a)
            b(zz(i))=a(i);
        end
        y =reshape(b,8,8);
        
end


