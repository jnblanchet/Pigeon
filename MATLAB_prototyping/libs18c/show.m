            % make sure we're good so far
            figure(5)
            centers = reshape([stats.Centroid],2,[]); % for display only
            rotated_centers = rot(90-orientation)' * centers;
            subplot(1,2,1);
            scatter(rotated_centers(1,:),rotated_centers(2,:))
            axis('equal')
            title('if there are still outliers at this point, we need to filter horizontally');
            subplot(2,2,2);
            imshow(f_ROI,[])
            hold on
            scatter(centers(1,:),centers(2,:),'filled')
            scatter(centers(1,ids(1)),centers(2,ids(1)),'filled')
            scatter(centers(1,ids(end)),centers(2,ids(end)),'filled')
            hold off
            title(num2str(numel(stats)));
            subplot(2,2,4);
            imshow(f,[])