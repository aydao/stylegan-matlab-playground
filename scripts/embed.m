% embed
im = imread("peppers.png");
imTarget = 2*(single(imresize(im, [256, 256]))./255) - 1;
gradAvgW = [];
gradSqAvgW = [];
% gradAvgX = [];
% gradSqAvgX = [];

%%
vgg = vgg16();
featureNet = dlnetwork(layerGraph(vgg.Layers(1:end-2)));
generator = stylegan.Generator('C:\code\internal\stylegan-matlab\weights\mccabe.mat');

%%
ax = axes(figure);
lr = 0.01;
for i = 1:1000
    [featureLoss, gradsW, gradsX, im] = dlfeval(@step, w, imTarget, generator, featureNet);
    [w, gradAvgW, gradSqAvgW] = adamupdate(...
               w, gradsW, gradAvgW, gradSqAvgW, i, lr);
    disp(extractdata(featureLoss));
    imagesc(ax, (extractdata(im) + 1)/2);
%     axis equal
    drawnow();
end


function [featureLoss, gradsW, gradsX, im] = step(w, imTarget, generator, featureNet)
    im = generator.synthesis(w);
%     mseLoss = mean((im - imTarget).^2, 'all');
    
    pooling = 2;
    prepIm = @(x) avgpool((x+1)/2*255, pooling, "Stride", pooling);
    imFeatures = featureNet.forward(prepIm(im), "Output", "conv3_2");
    targetFeatures = featureNet.forward(dlarray((imTarget+1)/2*255, "SSCB"), "Output", "conv3_2");
    featureLoss = mean((imFeatures - targetFeatures).^2, 'all');
    gradsW = dlgradient(featureLoss, w);
    gradsX = [];
end