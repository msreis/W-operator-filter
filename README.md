# W-operator-filter

A set of programs to design and apply W-operator filters on noisy binary images.


parse_image.pl: creates the pair of binary ideal/observed images, as well as the
                samples of different windows screened through them.

design_W_operator.pl: given a minimum subset obtained through the execution of
                      feature selection (e.g., using the featsel framework,
                      which is available at https://github.com/msreis/featsel) 
                      on a sample of a window of size n, designs a
                      W-operator of size n.

Example of a feature selection procedure using featsel:

./featsel -a es -n 3 -m 8 -c mce -f output/dat/sample_01_W_03.dat



filter_image.pl: uses a W-operator designed using design_W_operator.pl to screen
                 the observed image of parse_image.pl, hence obtaining an image
                 that has its salt-and-pepper noise filtered.


