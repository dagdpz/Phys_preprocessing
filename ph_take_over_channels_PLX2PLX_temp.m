filelist={'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_1-01.plx';
          'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_2-01.plx';
          'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_3-01.plx';
          'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_4-01.plx';
          'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_1-01.plx';
          'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_2-01.plx';
          'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_3-01.plx';
          'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_4-01.plx';
          'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_1-01.plx';
          'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_2-01.plx';};
filelist_ch={'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_1.plx';
             'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_2.plx';
             'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_3.plx';
             'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_4.plx';
             'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_1.plx';
             'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_2.plx';
             'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_3.plx';
             'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_4.plx';
             'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_1.plx';
             'C:\Users\lschneider\Desktop\Lindsey_temp\20160422_from_BB_blocks_2.plx';};
channels=[4,4,4,4,6,6,6,6,5,5];

for f=1:numel(channels)
other_channels_PLX_file=filelist{f};
specific_channel_PLX_file=filelist_ch{f};
channel=channels(f);
DAG_take_over_sortcode_PLX2PLX(other_channels_PLX_file,specific_channel_PLX_file,channel);

end